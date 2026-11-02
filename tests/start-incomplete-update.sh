#!/bin/bash
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/program/Utils/prompts.sh"
source "$repo/program/Core/Server/functions.sh"
INSTALL_DIR="$testdir/base"
TMPDIR="$testdir/tmp"
INSTANCE_TEXT="Test instance"
mkdir -p "$INSTALL_DIR/msm.d" "$TMPDIR"
log () { cat >/dev/null; }
requireRunnableInstance () { :; }
Core.Server::isRunning () { return 1; }
::hookable () { touch "$testdir/launch-attempted"; return 1; }

# Stop at the launch hook so no real server is started.
Core.Server::requestStart </dev/null || :
[[ -e $testdir/launch-attempted ]]
rm "$testdir/launch-attempted"
touch "$INSTALL_DIR/msm.d/update-incomplete"
for answer in no empty; do
  case $answer in
    no) input=$'n\n' ;;
    empty) input=$'\n' ;;
  esac
  if Core.Server::requestStart <<< "$input"; then exit 1; fi
  [[ ! -e $testdir/launch-attempted ]]
done
if Core.Server::requestStart </dev/null; then exit 1; fi
[[ ! -e $testdir/launch-attempted ]]
Core.Server::requestStart <<< 'yes' || :
[[ -e $testdir/launch-attempted ]]
printf 'Incomplete update prompt tests passed.\n'
