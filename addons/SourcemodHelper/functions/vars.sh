#! /bin/bash

SourcemodHelper::initVars () {
	SM_HOME="$USER_DIR/$APP/addons/sourcemod-helper"
	SM_FILECACHE_DIR="$SM_HOME/filecache"
	SM_TARGET_DIR="$INSTANCE_DIR/game/csgo"
	mkdir -p "$SM_FILECACHE_DIR" "$SM_HOME/tmp" || return
	SM_TMP_DIR=$(mktemp -d -p "$SM_HOME/tmp")
}
