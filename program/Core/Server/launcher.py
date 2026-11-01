#!/usr/bin/env python3
"""Run the server in its tmux window and copy redacted output to its log."""

import datetime
import os
from pathlib import Path
import signal
import subprocess
import sys


class Redactor:
    def __init__(self, secrets):
        self.secrets = tuple(secret for secret in secrets if secret)
        self.pending = b""

    def feed(self, chunk):
        output = bytearray()
        for byte in chunk:
            self.pending += bytes((byte,))
            while self.pending:
                if self.pending in self.secrets:
                    output.extend(b"[REDACTED]")
                    self.pending = b""
                elif any(secret.startswith(self.pending) for secret in self.secrets):
                    break
                else:
                    output.append(self.pending[0])
                    self.pending = self.pending[1:]
        return bytes(output)

    def finish(self):
        pending, self.pending = self.pending, b""
        return pending


def main():
    if len(sys.argv) < 6 or sys.argv[4] != "--":
        raise SystemExit("Usage: launcher.py WORKDIR LOGDIR EXIT_FILE -- COMMAND [ARG ...]")
    workdir, logdir, exit_file = sys.argv[1:4]
    redactor = Redactor(os.environb.get(name, b"") for name in
                        (b"MSM_REDACT_APIKEY", b"MSM_REDACT_GSLT"))
    code = 1
    child = None
    try:
        logfile = Path(logdir) / (datetime.datetime.now().strftime("%y%m%d_%H:%M:%S") + "-server.log")
        link = Path(logdir) / "server.log"
        with logfile.open("wb", buffering=0) as log:
            link.unlink(missing_ok=True)
            link.symlink_to(logfile.absolute())
            # The server shares the terminal's process group. Let it handle signals
            # while the launcher remains alive to record its exit status.
            for sig in (signal.SIGINT, signal.SIGTERM):
                signal.signal(sig, lambda signum, frame: None)
            child = subprocess.Popen(["stdbuf", "-o0", "-e0", *sys.argv[5:]],
                                     cwd=workdir, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT)
            while chunk := os.read(child.stdout.fileno(), 4096):
                output = redactor.feed(chunk)
                log.write(output)
                sys.stdout.buffer.write(output)
                sys.stdout.buffer.flush()
            output = redactor.finish()
            log.write(output)
            sys.stdout.buffer.write(output)
            sys.stdout.buffer.flush()
            code = child.wait()
            if code < 0:
                code = 128 - code
    except (OSError, ValueError) as exc:
        print("Server launcher failed: {}".format(exc), file=sys.stderr)
        if child is not None and child.poll() is None:
            child.terminate()
            child.wait()
    finally:
        Path(exit_file).write_text(str(code) + "\n")
    return code


if __name__ == "__main__":
    sys.exit(main())
