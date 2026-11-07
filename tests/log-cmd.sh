#!/bin/bash
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
MSM_DEBUG= MSM_LOGFILE=
source "$repo/program/Utils/output.sh"
MSM_LOGFILE="$testdir/log"
log-cmd bash -c 'printf "%s" "$1"' _ 'argument with spaces' > "$testdir/output"
[[ $(cat "$testdir/log") == 'argument with spaces' ]]
[[ $(cat "$testdir/output") == 'argument with spaces' ]]
if log-cmd bash -c 'exit 7' >/dev/null; then exit 1; fi
MSM_LOGFILE="$testdir/missing/log"
if log-cmd true >/dev/null 2>&1; then exit 1; fi
MSM_LOGFILE=
if log-cmd bash -c 'exit 7'; then exit 1; fi
if shopt -qo pipefail; then exit 1; fi
printf 'Command logging tests passed.\n'
