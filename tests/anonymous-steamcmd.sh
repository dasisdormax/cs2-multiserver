#!/bin/bash
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/cs2/app/functions/update.sh"
HOME="$testdir/home"
TMPDIR="$testdir/tmp"
INSTALL_DIR="$testdir/base"
LOGDIR="$testdir/logs"
mkdir -p "$HOME/Steam/appcache" "$TMPDIR" "$INSTALL_DIR/steamapps" "$LOGDIR"
touch "$HOME/Steam/appcache/appinfo.vdf" "$TMPDIR/steamcmd-out"
exec 3>/dev/null
STEAM_USERNAME=old_account
App::installSteamCMD () { :; }
App::installUpdater </dev/null
! declare -F App::printAdditionalConfig >/dev/null
printf '"buildid" "123"\n' > "$INSTALL_DIR/steamapps/appmanifest_730.acf"
log-cmd () {
  cp "$TMPDIR/steamcmd-script" "$testdir/script"
  if [[ ${ACTION:-} == update ]]; then
    printf "Success! App '730' fully installed\n" > "$MSM_LOGFILE"
  else
    printf '"730"\n{\n\t\t"branches"\n\t\t{\n\t\t\t"public"\n\t\t\t{\n\t\t\t\t"buildid" "123"\n\t\t\t}\n\t\t}\n}\n' > "$MSM_LOGFILE"
  fi
}
debug () { cat >/dev/null; }
error () { cat >/dev/null; }
log () { cat; }
catinfo () { cat >/dev/null; }
out () { cat >/dev/null; }
timestamp () { printf test; }
Core.Instance::select () { :; }
App::isUpToDate
grep -qx 'login anonymous' "$testdir/script"
! grep -q old_account "$testdir/script"
ACTION=update App::performUpdate
grep -qx 'login anonymous' "$testdir/script"
grep -qx 'app_update 730 ' "$testdir/script"
! grep -q old_account "$testdir/script"
printf 'Anonymous SteamCMD tests passed.\n'
