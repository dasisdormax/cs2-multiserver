#!/bin/bash
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/common.sh"
::registerHook () { true; }
builtin source "$repo/addons/SteamAPIHelper/functions/common.sh"
out () { cat; }
USER_DIR=$testdir
APP=cs2
INSTANCE_SUFFIX=base
MSM_ADDONS=SteamAPIHelper
APIKEY=
SteamAPIHelper::setup <<< '' > "$testdir/output"
grep -Fq 'https://steamcommunity.com/dev/apikey' "$testdir/output"
[[ ! $APIKEY ]]
SteamAPIHelper::setup <<< 'test key"$value' > "$testdir/output"
APIKEY=
builtin source "$SAH_CONFIG"
[[ $APIKEY == 'test key"$value' ]]
SteamAPIHelper::setup </dev/null > "$testdir/output"
[[ $APIKEY == 'test key"$value' ]]
printf 'Steam API setup tests passed.\n'
