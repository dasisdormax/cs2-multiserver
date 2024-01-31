#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

::registerHook before~App::validateGSLT SteamAPIHelper::handleGSLT

SteamAPIHelper::vars () {
	SAH_HOME="$USER_DIR/$APP/addons/steam-api-helper"
	SAH_CONFIG="$SAH_HOME/config.sh"
	SAH_TOKEN_DIR="$SAH_HOME/tokens"
	SAH_TOKEN_FILE="$SAH_TOKEN_DIR/$INSTANCE"
	[[ $APP == cs2 ]] && SAH_APPID=730
	mkdir -p "$SAH_HOME"
	mkdir -p "$SAH_TOKEN_DIR"
	[[ -e $SAH_CONFIG ]] || SteamAPIHelper::writeConfig
	[[ $APIKEY ]] || . "$SAH_CONFIG"
}

SteamAPIHelper::writeConfig () {
	cat > "$SAH_CONFIG" <<-EOF
		# Please add your Web API authentication key below
		# Get one at: https://steamcommunity.com/dev/apikey
		APIKEY="$APIKEY"
	EOF
}

SteamAPIHelper::requireKey () {
	[[ $APIKEY ]] && return
	warning <<-EOF
		A Steam Web API Authentication key is required to continue.
		Get a Steam API Key at:
	
		    **https://steamcommunity.com/dev/apikey**
		
	EOF
	read -p "Your Steam API Key: " APIKEY
	[[ $APIKEY ]] || return
	# TODO: Check if API Key is valid
	SteamAPIHelper::writeConfig
}