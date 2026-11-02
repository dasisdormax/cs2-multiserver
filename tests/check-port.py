#!/usr/bin/env python3
import socket
import subprocess
import sys
from pathlib import Path

check = Path(__file__).resolve().parents[1] / "cs2/app/check-port.py"


def probe(address, port):
    return subprocess.run([sys.executable, str(check), address, str(port)],
                          capture_output=True, text=True)


with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    assert probe("127.0.0.1", port).returncode != 0
    assert probe("127.0.0.2", port).returncode == 0
    assert probe("0.0.0.0", port).returncode != 0

with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.bind(("0.0.0.0", 0))
    assert probe("127.0.0.1", sock.getsockname()[1]).returncode != 0

assert probe("127.0.0.1", "invalid").returncode != 0
print("Port check tests passed.")
