#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

::registerHook before~App::validateGSLT TokenHelper::handle

TokenHelper::vars () {
	TH_HOME="$USER_DIR/$APP/addons/token-helper"
	TH_CONFIG="$TH_HOME/config.sh"
	TH_TOKEN_DIR="$TH_HOME/tokens"
	TH_TOKEN_FILE="$TH_TOKEN_DIR/$INSTANCE"
	[[ $APP == cs2 ]] && TH_APPID=730
	mkdir -p "$TH_HOME"
	mkdir -p "$TH_TOKEN_DIR"
	[[ -e $TH_CONFIG ]] || cat > "$TH_CONFIG" <<-EOF
		# Please add your Web API authentication key below
		# Get one at: https://steamcommunity.com/dev/apikey
		APIKEY=""
	EOF
	[[ $APIKEY ]] || . "$TH_CONFIG"
}

TokenHelper::checkExisting () {
	[[ -r $TH_TOKEN_FILE ]] || return
	local URL
	local TMPFILE
	local INVALID
	GSLT="$(cat "$TH_TOKEN_FILE")"
	echo "Checking if current login token is still valid ..." >&2
	URL="https://api.steampowered.com/IGameServersService/QueryLoginToken/v1/?key=$APIKEY&login_token=$GSLT"
	TMPFILE="$(mktemp)"
	wget -q "$URL" -O "$TMPFILE"
	INVALID="$(cat "$TMPFILE" | jq -r .response.is_banned 2>/dev/null)"
	rm "$TMPFILE"
	[[ $INVALID == false ]] || {
		echo "Existing login token is invalid or expired." >&2
		return 1
	}
}

TokenHelper::getToken () {
	local URL
	local DATA
	local MEMO
	local TMPFILE
	URL=https://api.steampowered.com/IGameServersService/CreateAccount/v1
	MEMO="[TH] $(hostname)@$INSTANCE"
	echo "Creating a new game server with memo '$MEMO'" >&2
	DATA="key=$APIKEY&appid=$TH_APPID&memo=$MEMO"
	TMPFILE="$(mktemp)"
	wget -q --post-data "$DATA" "$URL" -O "$TMPFILE" || {
		error <<< "Could not create login token. Make sure your APIKEY is correct."
		exit
	}
	GSLT="$(cat "$TMPFILE" | jq -r .response.login_token)"
	rm "$TMPFILE"
	[[ $GSLT ]] && echo "$GSLT" > "$TH_TOKEN_FILE"
}

TokenHelper::handle () {
	[[ $GSLT ]] && return
	TokenHelper::vars
	[[ $APIKEY ]] || {
		warning <<-EOT
			You have no Steam Web API Authentication key set. Without a key, 
			we cannot get a game server login token for you. Get one at

			    **https://steamcommunity.com/dev/apikey**

			and add it to the following file:

			    **$TH_CONFIG**
		EOT
		return 1
	}
	which jq >/dev/null 2>&1 || {
		fatal <<< "The program **jq** could not be found on your system!"
		return
	}
	TokenHelper::checkExisting || TokenHelper::getToken
}
