#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# Default list of plugins. If you think some should be added or removed, tell me
SM_BASE_PLUGINS="admin-flatfile adminhelp adminmenu antiflood basebans basechat basecommands basecomm basetriggers basevotes clientprefs playercommands"

SourcemodHelper::initVars () {
	SM_HOME="$USER_DIR/$APP/addons/sourcemod-helper"
	SM_CONFIG_DIR="$SM_HOME/configs"
	SM_TMP_DIR="$SM_HOME/tmp"
	SM_TARGET_DIR="$INSTANCE_DIR/$APP"
	SM_FILECACHE_DIR="$SM_HOME/filecache"
	mkdir -p "$SM_TMP_DIR"
	mkdir -p "$SM_FILECACHE_DIR"
	SM_TMP_DIR="$(mktemp -d -p "$SM_TMP_DIR")"
	SM_TMP_CONFIG_DIR="$SM_TMP_DIR/addons/sourcemod/configs"
	SM_TMP_PLUGIN_DIR="$SM_TMP_DIR/addons/sourcemod/plugins"
	SM_TMP_EXTENSION_DIR="$SM_TMP_DIR/addons/sourcemod/extensions"
}
