#!/usr/bin/env python3
import os
import importlib.util
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile

launcher = Path(__file__).resolve().parents[1] / "program/Core/Server/launcher.py"
spec = importlib.util.spec_from_file_location("launcher", launcher)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
redactor = module.Redactor([b"secret-key", b"token123"])
assert redactor.feed(b"before sec") == b"before sec"
assert redactor.feed(b"ret-key,more\n") == b"ret*********\n"
assert redactor.feed(b"token123 done") == b"token1** done"
assert redactor.finish() == b""
assert module.Redactor([b"", b""]).feed(b"ordinary output") == b"ordinary output"
assert module.Redactor([b"abc"]).feed(b"abc123 done") == b"abc*** done"
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
    assert select.select([process.stdout], [], [], 0.1)[0], "Credential prefix was delayed"
    output = os.read(process.stdout.fileno(), 7) + process.stdout.read()
    assert process.wait(timeout=3) == 7, process.stderr.read()
    assert output == b"secret**** token1** done"
    assert (root / "server.log").read_bytes() == b"prompt> " + output
    assert (root / "exit").read_text() == "7\n"
    result = subprocess.run(
        [sys.executable, str(launcher), directory, directory, str(root / "exit"),
         "--", sys.executable, "-c", "import os, signal; os.kill(os.getpid(), signal.SIGTERM)"],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
    )
    assert result.returncode == 143
    assert (root / "exit").read_text() == "143\n"
    process = subprocess.Popen(
        [sys.executable, str(launcher), directory, directory, str(root / "exit"),
         "--", sys.executable, "-c",
         "import signal, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); print('ready', flush=True); time.sleep(60)"],
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    assert select.select([process.stdout], [], [], 3)[0], "Child did not start"
    assert process.stdout.readline() == b"ready\n"
    process.send_signal(signal.SIGUSR1)
    assert process.wait(timeout=3) == 137, process.stderr.read()
    assert (root / "exit").read_text() == "137\n"
print("Launcher tests passed.")
