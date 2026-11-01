#!/usr/bin/env python3
import os
from pathlib import Path
import select
import subprocess
import sys

script = Path(__file__).resolve().parents[1] / "program/Core/Server/redact.py"
env = dict(os.environ, MSM_REDACT_APIKEY="secret-key", MSM_REDACT_GSLT="token123")
process = subprocess.Popen(
    [sys.executable, str(script)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, env=env
)
process.stdin.write(b"prompt> ")
process.stdin.flush()
assert select.select([process.stdout], [], [], 2)[0], "Output waited for a newline"
assert os.read(process.stdout.fileno(), 8) == b"prompt> "
process.stdin.write(b"secret-")
process.stdin.flush()
assert not select.select([process.stdout], [], [], 0.1)[0]
process.stdin.write(b"key token123 done")
process.stdin.close()
assert process.stdout.read() == b"[REDACTED] [REDACTED] done"
assert process.wait() == 0
print("Streaming redaction tests passed.")
