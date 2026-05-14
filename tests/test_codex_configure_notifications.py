from __future__ import annotations

import importlib.machinery
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


def load_codex_configure_notifications_module():
    script_path = (
        Path(__file__).resolve().parents[1]
        / "bin"
        / "codex_configure_notifications.py"
    )
    loader = importlib.machinery.SourceFileLoader(
        "codex_configure_notifications", str(script_path)
    )
    spec = importlib.util.spec_from_loader(loader.name, loader)
    if spec is None:
        raise RuntimeError("Could not create import spec")

    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module
    loader.exec_module(module)
    return module


codex_configure_notifications = load_codex_configure_notifications_module()


class CodexConfigureNotificationsTest(unittest.TestCase):
    def test_appends_tui_section_when_missing(self):
        source = 'model = "gpt-5.5"\n'

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(
            updated,
            'model = "gpt-5.5"\n'
            "\n"
            "[tui]\n"
            'notifications = ["agent-turn-complete", "approval-requested"]\n'
            'notification_method = "bel"\n'
            'notification_condition = "always"\n',
        )

    def test_updates_existing_tui_section_before_subtables(self):
        source = (
            "[tui]\n"
            'status_line = ["model-with-reasoning", "current-dir"]\n'
            "notifications = true\n"
            "\n"
            "[tui.model_availability_nux]\n"
            '"gpt-5.5" = 4\n'
        )

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(
            updated,
            "[tui]\n"
            'status_line = ["model-with-reasoning", "current-dir"]\n'
            'notifications = ["agent-turn-complete", "approval-requested"]\n'
            "\n"
            'notification_method = "bel"\n'
            'notification_condition = "always"\n'
            "[tui.model_availability_nux]\n"
            '"gpt-5.5" = 4\n',
        )

    def test_replaces_duplicate_notification_keys(self):
        source = (
            "[tui]\n"
            "notifications = false\n"
            'notification_method = "auto"\n'
            'notification_method = "osc9"\n'
        )

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(updated.count("notification_method"), 1)
        self.assertIn('notification_method = "bel"\n', updated)

    def test_replaces_entire_multiline_notification_array(self):
        source = (
            "[tui]\n"
            "notifications = [\n"
            '    "agent-turn-complete",\n'
            '    "approval-requested",\n'
            "]\n"
            'status_line = ["model-with-reasoning"]\n'
        )

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(
            updated,
            "[tui]\n"
            'notifications = ["agent-turn-complete", "approval-requested"]\n'
            'status_line = ["model-with-reasoning"]\n'
            "\n"
            'notification_method = "bel"\n'
            'notification_condition = "always"\n',
        )

    def test_replaces_entire_multiline_string_value(self):
        source = (
            "[tui]\n"
            'notification_method = """\n'
            "osc9\n"
            '"""\n'
            "notification_condition = 'always'\n"
        )

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(
            updated,
            "[tui]\n"
            'notification_method = "bel"\n'
            'notification_condition = "always"\n'
            "\n"
            'notifications = ["agent-turn-complete", "approval-requested"]\n',
        )

    def test_is_idempotent(self):
        source = (
            "[tui]\n"
            'notifications = ["agent-turn-complete", "approval-requested"]\n'
            'notification_method = "bel"\n'
            'notification_condition = "always"\n'
        )

        updated = codex_configure_notifications.configure_text(source)

        self.assertEqual(updated, source)

    def test_configure_file_creates_parent_and_reports_changes(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / ".codex" / "config.toml"

            self.assertTrue(
                codex_configure_notifications.configure_file(config_path)
            )
            self.assertFalse(
                codex_configure_notifications.configure_file(config_path)
            )
            self.assertIn(
                'notification_condition = "always"',
                config_path.read_text(),
            )


if __name__ == "__main__":
    unittest.main()
