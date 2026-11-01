#!/usr/bin/env python3
"""Remove configured credentials from the server's output as bytes arrive."""

import os
import sys

secrets = tuple(
    value for name in ("MSM_REDACT_APIKEY", "MSM_REDACT_GSLT")
    if (value := os.environb.get(name.encode()))
)
pending = b""
while chunk := os.read(sys.stdin.fileno(), 4096):
    output = bytearray()
    for byte in chunk:
        pending += bytes((byte,))
        while pending:
            if pending in secrets:
                output.extend(b"[REDACTED]")
                pending = b""
            elif any(secret.startswith(pending) for secret in secrets):
                break
            else:
                output.append(pending[0])
                pending = pending[1:]
    sys.stdout.buffer.write(output)
    sys.stdout.buffer.flush()

sys.stdout.buffer.write(pending)
sys.stdout.buffer.flush()
