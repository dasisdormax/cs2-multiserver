#!/bin/bash
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
source "$repo/program/Core/BaseInstallation/functions.sh"
source "$repo/cs2/app/functions/update.sh"
INSTALL_DIR="$testdir/base"
mkdir -p "$INSTALL_DIR/msm.d" "$INSTALL_DIR/steamapps"
requireUpdater () { true; }
log () { cat >/dev/null; }
info () { cat >/dev/null; }
warning () { cat >/dev/null; }
error () { cat >/dev/null; }
Core.BaseInstallation::startUpdate () { printf '%s' "$ACTION" > "$testdir/action"; }
Core.BaseInstallation::isUpToDate () { return 0; }
printf update > "$INSTALL_DIR/msm.d/update-incomplete"
Core.BaseInstallation::requestUpdate
[[ $(cat "$testdir/action") == repair ]]
touch "$INSTALL_DIR/msm.d/cloned-from"
Core.BaseInstallation::requestUpdate
[[ $(cat "$testdir/action") == update ]]
rm "$INSTALL_DIR/msm.d/update-incomplete" "$INSTALL_DIR/msm.d/cloned-from"
Core.BaseInstallation::isUpToDate () { return 9; }
if Core.BaseInstallation::requestUpdate; then exit 1; fi

source "$repo/program/AddonEngine/functions.sh"
list-contains () { [[ " $1 " == *" $2 "* ]]; }
::update () { true; }
THIS_DIR=$repo
USER_DIR="$testdir/user"
for addons in 'SourcemodHelper' 'PluginHelper' 'SourcemodHelper PluginHelper' 'PluginHelper SourcemodHelper'; do
  ::init
  MSM_ADDONS=$addons ::loadAddons
  [[ $RequestedModules == ' PluginHelper' ]]
done
[[ $(::moduleDir PluginHelper) == "$repo/addons/PluginHelper" ]]
mkdir -p "$testdir/other/addons/ExamplePlugin"
ln -s ExamplePlugin "$testdir/other/addons/ExampleAlias"
THIS_DIR="$testdir/other"
::init
MSM_ADDONS='ExampleAlias ExamplePlugin' ::loadAddons
[[ $RequestedModules == ' ExamplePlugin' ]]
THIS_DIR=$repo
(
  set +u
  source "$repo/common.sh"
  source "$repo/program/Utils/other.sh"
  source "$repo/program/AddonEngine/functions.sh"
  THIS_DIR=$repo
  USER_DIR="$testdir/user"
  ::init
  MSM_ADDONS='SourcemodHelper PluginHelper'
  ::loadAddons || true
  [[ $Modules == 'PluginHelper ' ]]
  [[ $ALL_HOOKS == *'after~App::buildLaunchCommand@PluginHelper::updateInstance'* ]]
)

::registerHook () { true; }
source "$repo/addons/PluginHelper/functions/hooks.sh"
SM_TARGET_DIR="$testdir/instance/game/csgo"
SM_TMP_DIR="$testdir/stage"
mkdir -p "$SM_TARGET_DIR/addons/counterstrikesharp/plugins/test" "$SM_TMP_DIR"
printf 'Game_LowViolence csgo_lv\n' > "$SM_TARGET_DIR/gameinfo.gi"
printf 'keep' > "$SM_TARGET_DIR/addons/counterstrikesharp/plugins/test/test.dll"
PluginHelper::loadPackage () {
  mkdir -p addons/metamod addons/counterstrikesharp/plugins/test
  printf replace > addons/counterstrikesharp/plugins/test/test.dll
  printf framework > addons/metamod/framework.so
}
PluginHelper::updateInstance
[[ $(cat "$SM_TARGET_DIR/addons/counterstrikesharp/plugins/test/test.dll") == keep ]]
[[ -f "$SM_TARGET_DIR/addons/metamod/framework.so" ]]
[[ $(grep -c 'Game csgo/addons/metamod' "$SM_TARGET_DIR/gameinfo.gi") == 1 ]]
mkdir -p "$SM_TMP_DIR"
PluginHelper::updateInstance
[[ $(grep -c 'Game csgo/addons/metamod' "$SM_TARGET_DIR/gameinfo.gi") == 1 ]]
printf 'Recovery and addon tests passed.\n'
