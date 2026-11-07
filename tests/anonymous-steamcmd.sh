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
    cat > "$MSM_LOGFILE" <<'EOF'
"730"
{
		"branches"
		{
			"public"
			{
				"buildid" "123"
			}
		}
}
EOF
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
