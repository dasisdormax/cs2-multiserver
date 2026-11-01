#!/bin/bash
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/common.sh"
builtin source "$repo/program/Core/Setup/functions.sh"
log () { cat; }
THIS_DIR=$repo
USER_DIR=$testdir
mkdir -p "$USER_DIR/addons/Extra" "$USER_DIR/addons/PluginHelper"
printf 'local ADDON_DESCRIPTION="Extra addon"\n' > "$USER_DIR/addons/Extra/addon.info"
printf 'local ADDON_DESCRIPTION="Duplicate"\n' > "$USER_DIR/addons/PluginHelper/addon.info"
Core.Setup::selectAddons <<< '' > "$testdir/output"
[[ $MSM_ADDONS == 'PluginHelper SteamAPIHelper' ]]
grep -Fq 'Addons hook into the server management to add optional features.' "$testdir/output"
grep -Fq '1. [X] PluginHelper - Installs Metamod' "$testdir/output"
grep -Fq '2. [X] SteamAPIHelper' "$testdir/output"
grep -Fq '3. [ ] Extra - Extra addon' "$testdir/output"
! grep -q 'AddonTemplate\|Duplicate' "$testdir/output"
Core.Setup::selectAddons <<< $'invalid\n1\n2\n3\n' > "$testdir/output"
[[ $MSM_ADDONS == Extra ]]
grep -q 'Invalid selection' "$testdir/output"
if Core.Setup::selectAddons </dev/null > "$testdir/output"; then exit 1; fi
printf 'Addon selection tests passed.\n'
