#!/usr/bin/env python3
"""Check whether the configured IPv4 UDP address can be bound."""

import socket
import sys

try:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind((sys.argv[1], int(sys.argv[2])))
except (OSError, ValueError, OverflowError) as exc:
    print(exc, file=sys.stderr)
    sys.exit(1)
