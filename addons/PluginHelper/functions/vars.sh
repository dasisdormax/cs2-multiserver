#! /bin/bash

PluginHelper::initVars () {
	PH_HOME="$USER_DIR/$APP/addons/plugin-helper"
	PH_FILECACHE_DIR="$PH_HOME/filecache"
	PH_TARGET_DIR="$INSTANCE_DIR/game/csgo"
	mkdir -p "$PH_FILECACHE_DIR" "$PH_HOME/tmp" || return
	PH_TMP_DIR=$(mktemp -d -p "$PH_HOME/tmp")
}
