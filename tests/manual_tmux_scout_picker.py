"""Live smoke test: uv run --with pyte python tests/manual_tmux_scout_picker.py.

Requires the loaded dotfiles tmux config and at least one Scout agent.
Creates its own session/client; never sends input to an agent pane.
"""

import fcntl
import os
import pty
import select
import struct
import subprocess
import termios
import time
import uuid

import pyte


def tmux(*args):
    return subprocess.check_output(["tmux", *args], text=True).strip()


session = "scout-layout-test-" + uuid.uuid4().hex[:8]
master, slave = pty.openpty()
fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 45, 180, 0, 0))


class Screen(pyte.Screen):
    def write_process_input(self, data):
        os.write(master, data.encode())

    def report_device_status(self, mode, **kwargs):
        if not kwargs.get("private"):
            super().report_device_status(mode)


screen = Screen(180, 45)
stream = pyte.ByteStream(screen)


def pump(seconds=1):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if select.select([master], [], [], 0.1)[0]:
            try:
                chunk = os.read(master, 65536)
            except OSError:
                break
            if not chunk:
                break
            stream.feed(chunk)


def send(data):
    os.write(master, data)
    pump()


def picker_open():
    return any("tmux-scout" in row for row in screen.display[:2])


def client_session(tty):
    clients = tmux("list-clients", "-F", "#{client_tty}\t#{session_name}")
    return dict(row.split("\t", 1) for row in clients.splitlines())[tty]


client = None
try:
    tmux("new-session", "-d", "-s", session, "-x", "180", "-y", "45")
    env = dict(os.environ, TERM="xterm-256color")
    env.pop("TMUX", None)
    client = subprocess.Popen(
        ["tmux", "attach-session", "-t", "=" + session],
        stdin=slave, stdout=slave, stderr=slave, env=env,
    )
    tty = os.ttyname(slave)
    pump(2)
    send(b"\x02O")
    pump(2)
    assert picker_open(), "Full-height picker did not open:\n" + "\n".join(screen.display)
    # Native tmux and fzf each draw an outer border, with one padding column.
    assert "│" not in screen.display[20][3:-3], "Unexpected preview divider"
    assert not any("pane preview" in row or "expand preview" in row for row in screen.display)
    print("PASS: full-height popup without preview at 180x45")

    send(b"\x1b")
    assert client_session(tty) == session
    assert not picker_open(), "Esc did not close popup"
    send(b"\x02O")
    pump(2)
    send(b"\r")
    target = client_session(tty)
    assert target != session, "Enter did not switch to the selected agent"
    print("PASS: Esc dismisses; Enter switches to an agent session")
finally:
    if client is not None:
        subprocess.run(["tmux", "detach-client", "-t", os.ttyname(slave)], capture_output=True)
        pump()
        try:
            client.wait(timeout=3)
        except subprocess.TimeoutExpired:
            client.kill()
            client.wait(timeout=3)
    subprocess.run(["tmux", "kill-session", "-t", "=" + session], capture_output=True)
    os.close(master)
    os.close(slave)
