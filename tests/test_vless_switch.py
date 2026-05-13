from __future__ import annotations

import argparse
import base64
import importlib.machinery
import importlib.util
import sys
import unittest
from pathlib import Path


def load_vless_switch_module():
    script_path = Path(__file__).resolve().parents[1] / "bin" / "vless-switch"
    loader = importlib.machinery.SourceFileLoader("vless_switch", str(script_path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    if spec is None:
        raise RuntimeError("Could not create import spec for vless-switch")

    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module
    loader.exec_module(module)
    return module


vless_switch = load_vless_switch_module()


class VlessSwitchTest(unittest.TestCase):
    def test_decode_subscription_keeps_only_vless_entries(self):
        raw_entries = "\n".join(
            [
                "vmess://ignored",
                "vless://uuid@example.com:443?type=tcp&security=tls#node",
            ]
        )
        encoded = base64.b64encode(raw_entries.encode("utf-8")).decode("ascii")

        self.assertEqual(
            vless_switch.decode_subscription(encoded),
            ["vless://uuid@example.com:443?type=tcp&security=tls#node"],
        )

    def test_parse_reality_entry(self):
        entry = vless_switch.parse_entry(
            "vless://abc@example.com:8443"
            "?type=tcp&security=reality&sni=www.example.org"
            "&pbk=public-key&sid=short&fp=chrome&alpn=h2,http/1.1"
            "&flow=xtls-rprx-vision#Reality%20Node"
        )

        self.assertEqual(entry.label, "Reality Node")
        self.assertEqual(entry.host, "example.com")
        self.assertEqual(entry.port, 8443)
        self.assertEqual(entry.security, "reality")
        self.assertEqual(entry.transport, "tcp")
        self.assertEqual(entry.server_name, "www.example.org")
        self.assertEqual(entry.public_key, "public-key")
        self.assertEqual(entry.short_id, "short")
        self.assertEqual(entry.fingerprint, "chrome")
        self.assertEqual(entry.alpn, ("h2", "http/1.1"))

    def test_build_config_includes_ssh_bypasses(self):
        entry = vless_switch.parse_entry(
            "vless://abc@example.com:443?type=tcp&security=tls&sni=example.com#node"
        )

        config = vless_switch.build_config(entry, ssh_client_ip="203.0.113.7")
        tun = config["inbounds"][0]
        route = config["route"]

        self.assertEqual(tun["tag"], "sbtun")
        self.assertEqual(tun["interface_name"], "sbtun")
        self.assertTrue(tun["auto_route"])
        self.assertTrue(tun["strict_route"])
        self.assertEqual(tun["stack"], "system")
        self.assertIn("100.64.0.0/10", tun["route_exclude_address"])
        self.assertIn("203.0.113.7/32", tun["route_exclude_address"])
        self.assertTrue(route["auto_detect_interface"])
        self.assertEqual(route["final"], "vless-out")
        self.assertEqual(
            route["rules"][0],
            {
                "network": "tcp",
                "source_port": 22,
                "action": "route",
                "outbound": "direct",
            },
        )
        self.assertEqual(
            route["rules"][1],
            {
                "network": "tcp",
                "port": 22,
                "action": "route",
                "outbound": "direct",
            },
        )

    def test_unsupported_transport_is_rejected(self):
        entry = vless_switch.parse_entry(
            "vless://abc@example.com:443?type=ws&security=tls#node"
        )

        with self.assertRaisesRegex(vless_switch.VlessSwitchError, "unsupported"):
            vless_switch.build_config(entry)

    def test_non_dry_run_connect_requires_root_before_fetch(self):
        args = argparse.Namespace(
            dry_run=False,
            subscription_url="https://example.invalid/sub",
            pick=1,
            config_path="/tmp/config.json",
            service_name="sing-box",
            sing_box_binary="sing-box",
        )

        original_is_effective_root = vless_switch.is_effective_root
        original_fetch_subscription = vless_switch.fetch_subscription
        fetch_called = False

        def fake_is_effective_root():
            return False

        def fake_fetch_subscription(_url):
            nonlocal fetch_called
            fetch_called = True
            return ""

        vless_switch.is_effective_root = fake_is_effective_root
        vless_switch.fetch_subscription = fake_fetch_subscription
        try:
            with self.assertRaises(vless_switch.VlessSwitchError):
                vless_switch.handle_connect(args)
        finally:
            vless_switch.is_effective_root = original_is_effective_root
            vless_switch.fetch_subscription = original_fetch_subscription

        self.assertFalse(fetch_called)


if __name__ == "__main__":
    unittest.main()
