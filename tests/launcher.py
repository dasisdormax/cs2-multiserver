#!/usr/bin/env python3
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile

launcher = Path(__file__).resolve().parents[1] / "program/Core/Server/launcher.py"
env = dict(os.environ, MSM_REDACT_APIKEY="secret-key", MSM_REDACT_GSLT="token123")
child_code = """
import os, sys, time
os.write(1, b'prompt> ')
assert sys.stdin.readline() == 'hello\\n'
os.write(1, b'secret-')
time.sleep(0.2)
os.write(1, b'key token123 done')
sys.exit(7)
"""
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    process = subprocess.Popen(
        [sys.executable, str(launcher), directory, directory, str(root / "exit"),
         "--", sys.executable, "-c", child_code],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
    )
    assert select.select([process.stdout], [], [], 3)[0], "Output waited for a newline"
    assert os.read(process.stdout.fileno(), 8) == b"prompt> "
    process.stdin.write(b"hello\n")
    process.stdin.flush()
    assert not select.select([process.stdout], [], [], 0.1)[0]
    output = process.stdout.read()
    assert process.wait(timeout=3) == 7, process.stderr.read()
    assert output == b"[REDACTED] [REDACTED] done"
    assert (root / "server.log").read_bytes() == b"prompt> " + output
    assert (root / "exit").read_text() == "7\n"
    result = subprocess.run(
        [sys.executable, str(launcher), directory, directory, str(root / "exit"),
         "--", sys.executable, "-c", "import os, signal; os.kill(os.getpid(), signal.SIGTERM)"],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
    )
    assert result.returncode == 143
    assert (root / "exit").read_text() == "143\n"
print("Launcher tests passed.")
