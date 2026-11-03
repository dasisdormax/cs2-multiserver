#!/usr/bin/env python3
"""Run the server in its tmux window and copy redacted output to its log."""

import datetime
import os
from pathlib import Path
import re
import signal
import subprocess
import sys


class Redactor:
    def __init__(self, secrets):
        self.prefixes = tuple(secret[:6] for secret in secrets if secret)
        self.max_prefix = max((len(prefix) for prefix in self.prefixes), default=0)
        self.recent = b""
        self.masking = False

    def feed(self, chunk):
        if not self.prefixes:
            return chunk
        output = bytearray()
        pos = 0
        while pos < len(chunk):
            if self.masking:
                match = re.search(rb"[^0-9a-zA-Z+_-]", chunk[pos:])
                end = pos + match.start() if match else len(chunk)
                output.extend(b"*" * (end - pos))
                pos = end
                if pos == len(chunk):
                    break
                self.masking = False

            data = self.recent + chunk[pos:]
            offset = len(self.recent)
            # The byte-wise filter starts masking at the first prefix to end.
            ends = [index + len(prefix) for prefix in self.prefixes
                    if (index := data.find(prefix)) >= 0]
            if not ends:
                output.extend(chunk[pos:])
                self.recent = data[-(self.max_prefix - 1):] if self.max_prefix > 1 else b""
                break
            end = min(ends)
            consumed = end - offset
            output.extend(chunk[pos:pos + consumed])
            pos += consumed
            self.recent = b""
            self.masking = True
        return bytes(output)

    def finish(self):
        return b""


def main():
    if len(sys.argv) < 6 or sys.argv[4] != "--":
        raise SystemExit("Usage: launcher.py WORKDIR LOGDIR EXIT_FILE -- COMMAND [ARG ...]")
    workdir, logdir, exit_file = sys.argv[1:4]
    redactor = Redactor(os.environb.get(name, b"") for name in
                        (b"MSM_REDACT_APIKEY", b"MSM_REDACT_GSLT"))
    code = 1
    child = None
    kill_requested = False

    def force_stop(signum, frame):
        nonlocal kill_requested
        kill_requested = True
        if child is not None:
            try:
                child.kill()
            except ProcessLookupError:
                pass

    signal.signal(signal.SIGUSR1, force_stop)
    try:
        logfile = Path(logdir) / (datetime.datetime.now().strftime("%y%m%d_%H:%M:%S") + "-server.log")
        link = Path(logdir) / "server.log"
        with logfile.open("wb") as log:
            link.unlink(missing_ok=True)
            link.symlink_to(logfile.absolute())
            # The server shares the terminal's process group. Let it handle signals
            # while the launcher remains alive to record its exit status.
            for sig in (signal.SIGINT, signal.SIGTERM):
                signal.signal(sig, lambda signum, frame: None)
            child = subprocess.Popen(["stdbuf", "-o0", "-e0", *sys.argv[5:]],
                                     cwd=workdir, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT)
            if kill_requested:
                force_stop(None, None)
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
