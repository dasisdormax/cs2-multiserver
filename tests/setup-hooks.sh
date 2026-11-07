#!/bin/bash
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/common.sh"
builtin source "$repo/program/Utils/other.sh"
builtin source "$repo/program/AddonEngine/functions.sh"
builtin source "$repo/program/Core/Setup/functions.sh"
out () { cat; }
info () { cat; }
log () { cat; }
success () { cat; }
THIS_DIR=$repo
USER_DIR=$testdir
APP=cs2
THIS_COMMAND=msm
CFG_DIR=$testdir/cfg
CFG=$CFG_DIR/defaults.conf
mkdir -p "$CFG_DIR"
cat > "$CFG" <<'CONFIG'
MSM_ADDONS=""
CUSTOM_SETTING='keep this value'
CONFIG
Core.Setup::loadConfig () { builtin source "$CFG"; }
::init

# Repeat setup loads a newly enabled addon and prompts before success.
Core.Setup::beginSetup <<< $'2\n\ntest key"$value' > "$testdir/output"
[[ $MSM_ADDONS == SteamAPIHelper ]]
APIKEY=
builtin source "$SAH_CONFIG"
[[ $APIKEY == 'test key"$value' ]]
builtin source "$CFG"
[[ $MSM_ADDONS == SteamAPIHelper && $CUSTOM_SETTING == 'keep this value' ]]
python3 - "$testdir/output" <<'PY'
import sys
text = open(sys.argv[1]).read()
assert text.index('https://steamcommunity.com/dev/apikey') < text.index('Basic Setup Complete!')
assert 'If you want to start over, delete that file' in text
PY

# Saved choices stay selected. An existing key needs no further input.
cp "$CFG" "$testdir/before"
Core.Setup::beginSetup <<< '' > "$testdir/output"
cmp "$CFG" "$testdir/before"
grep -Fq '2. [X] SteamAPIHelper' "$testdir/output"
! grep -Fq 'https://steamcommunity.com/dev/apikey' "$testdir/output"

# A loaded but deselected addon must not ask for a key.
APIKEY=
rm "$SAH_CONFIG"
Core.Setup::beginSetup <<< $'2\n' > "$testdir/output"
builtin source "$CFG"
[[ ! $MSM_ADDONS ]]
! grep -Fq 'https://steamcommunity.com/dev/apikey' "$testdir/output"

# A custom hook sees the saved configuration before success output.
probe () {
	[[ $1 == Core.Setup::afterConfig ]]
	builtin source "$CFG"
	[[ $MSM_ADDONS == SteamAPIHelper ]]
	printf 'Setup hook ran.\n'
}
::registerHook Core.Setup::afterConfig probe
Core.Setup::beginSetup <<< $'2\n\n' > "$testdir/output"
grep -Fq 'Press Enter to add the key later.' "$testdir/output"
python3 - "$testdir/output" <<'PY'
import sys
text = open(sys.argv[1]).read()
assert text.index('Setup hook ran.') < text.index('Basic Setup Complete!')
PY

# Cancelling selection does not change the saved configuration.
cp "$CFG" "$testdir/before"
if Core.Setup::beginSetup </dev/null > "$testdir/output"; then exit 1; fi
cmp "$CFG" "$testdir/before"
! grep -Fq 'Basic Setup Complete!' "$testdir/output"
# Initial setup saves the config before the same addon prompt and success output.
(
	CFG_DIR=$testdir/initial/cfg
	CFG=$CFG_DIR/defaults.conf
	APP_DIR=$repo/cs2/app
	TMPDIR=$testdir/initial/tmp
	LOGDIR=$testdir/initial/log
	INSTCFGDIR=$testdir/initial/instance
	ADMIN=$USER
	DEFAULT_INSTANCE=
	APIKEY=
	rm -f "$SAH_CONFIG"
	::init
	ALL_HOOKS=" "
	App::installUpdater () { true; }
	Core.BaseInstallation::isExisting () { true; }
	Core.Instance::select () { INSTANCE_SUFFIX=base; }
	App::finalizeInstance () { true; }
	Core.BaseInstallation::applyPermissions () { true; }
	Core.Setup::validateConfig () { true; }
	make-readable () { true; }
	try () { true; }
	Core.Setup::setupAsAdmin <<< $'1\n\n' > "$testdir/initial-output"
	builtin source "$CFG"
	[[ $MSM_ADDONS == SteamAPIHelper ]]
	python3 - "$testdir/initial-output" <<'PYTHON'
import sys
text = open(sys.argv[1]).read()
assert text.index('https://steamcommunity.com/dev/apikey') < text.index('Basic Setup Complete!')
PYTHON
)
printf 'Setup hook tests passed.\n'
