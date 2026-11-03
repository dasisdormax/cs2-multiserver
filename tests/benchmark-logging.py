#!/usr/bin/env python3
"""Compare historical server console logging paths with the current launcher."""

import argparse
import errno
import os
from pathlib import Path
import pty
import resource
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / "program/Core/Server/launcher.py"
LINE = b"[Server] Player connected; map=de_dust2; status=running; tick=12345\n"


def produce(size):
    # One write per line approximates frequent console messages.
    remaining = size
    while remaining:
        chunk = LINE[:min(len(LINE), remaining)]
        view = memoryview(chunk)
        while view:
            view = view[os.write(1, view):]
        remaining -= len(chunk)


def run_case(name, directory, size):
    log = directory / (name + ".log")
    producer = [sys.executable, str(Path(__file__).resolve()), "--produce", str(size)]
    command = shlex.join(producer)
    if name == "direct":
        args = producer
    elif name == "unbuffer":
        args = ["bash", "-o", "pipefail", "-c",
                'unbuffer -p "$@" | tee "$BENCH_LOG"', "benchmark", *producer]
    elif name == "script":
        args = ["script", "-q", "-e", "-c", command, str(log)]
    elif name == "stdbuf":
        args = ["bash", "-o", "pipefail", "-c",
                'stdbuf -o0 -e0 "$@" 2>&1 | tee "$BENCH_LOG"', "benchmark", *producer]
    else:
        args = [sys.executable, str(LAUNCHER), str(ROOT), str(directory),
                str(directory / "exit-code"), "--", *producer]

    env = dict(os.environ, BENCH_LOG=str(log), MSM_REDACT_APIKEY="sample-api-key",
               MSM_REDACT_GSLT="sample-gslt-token")
    master, slave = pty.openpty()
    before = resource.getrusage(resource.RUSAGE_CHILDREN)
    start = time.monotonic()
    try:
        # Keep stdin open for unbuffer -p until the producer finishes.
        process = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=slave,
                                   stderr=slave, env=env)
        os.close(slave)
        slave = None
        received = 0
        while True:
            try:
                data = os.read(master, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not data:
                break
            received += len(data)
        process.stdin.close()
        status = process.wait()
    finally:
        os.close(master)
        if slave is not None:
            os.close(slave)
    elapsed = time.monotonic() - start
    after = resource.getrusage(resource.RUSAGE_CHILDREN)
    cpu = (after.ru_utime + after.ru_stime) - (before.ru_utime + before.ru_stime)
    if status:
        raise RuntimeError(f"{name} exited with status {status}")
    if name == "python":
        log = directory / "server.log"
    logged = log.stat().st_size if name != "direct" else 0
    if received < size or (name != "direct" and logged < size):
        raise RuntimeError(f"{name} lost output: terminal={received}, log={logged}, input={size}")
    return elapsed, cpu, received, logged


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mib", type=float, default=8, help="input MiB per run (default: 8)")
    parser.add_argument("--runs", type=int, default=3, help="runs per approach (default: 3)")
    parser.add_argument("--directory", type=Path, help="directory for temporary logs (default: system temp)")
    parser.add_argument("--produce", type=int, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.produce is not None:
        produce(args.produce)
        return
    size = int(args.mib * 1024 * 1024)
    if size < 1 or args.runs < 1:
        parser.error("--mib and --runs must be positive")
    cases = ["direct", "unbuffer", "script", "stdbuf", "python"]
    required = {"unbuffer": "unbuffer", "script": "script", "stdbuf": "stdbuf", "python": "stdbuf"}
    for case, executable in required.items():
        if not shutil.which(executable):
            print(f"Skipping {case}: {executable} is not installed", file=sys.stderr)
            cases.remove(case)
    print("Terminal output goes to a drained pseudo-terminal, not a terminal emulator or tmux.")
    print("CPU includes the producer and all child processes; it excludes the terminal reader.")
    print("Python logging uses two configured credential prefixes. No credentials occur in the input.")
    print(f"Input: {size:,} bytes per run. Logs are temporary.\n")
    print(f"{'approach':<10} {'run':>3} {'wall s':>9} {'CPU s':>9} {'CPU %':>8} {'MiB/s':>9} {'terminal B':>12} {'log B':>12}")
    with tempfile.TemporaryDirectory(prefix="msm-log-bench-", dir=args.directory) as tmp:
        directory = Path(tmp)
        for run in range(1, args.runs + 1):
            # Rotate the order to reduce systematic effects from cache and warmup.
            ordered = cases[(run - 1) % len(cases):] + cases[:(run - 1) % len(cases)]
            for case in ordered:
                elapsed, cpu, received, logged = run_case(case, directory, size)
                print(f"{case:<10} {run:>3} {elapsed:>9.3f} {cpu:>9.3f} {100 * cpu / elapsed:>8.1f} "
                      f"{size / 1048576 / elapsed:>9.2f} {received:>12} {logged:>12}", flush=True)


if __name__ == "__main__":
    main()
