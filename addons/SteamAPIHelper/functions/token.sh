#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SteamAPIHelper::checkExistingToken () {
	[[ -r $SAH_TOKEN_FILE ]] || return
	local URL
	local TMPFILE
	local INVALID
	GSLT="$(cat "$SAH_TOKEN_FILE")"
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

SteamAPIHelper::getNewToken () {
	local URL
	local DATA
	local MEMO
	local TMPFILE
	URL=https://api.steampowered.com/IGameServersService/CreateAccount/v1
	MEMO="[cs2-multiserver] $(hostname), instance @$INSTANCE"
	echo "Creating a new game server with memo '$MEMO'" >&2
	DATA="key=$APIKEY&appid=$SAH_APPID&memo=$MEMO"
	TMPFILE="$(mktemp)"
	wget -q --post-data "$DATA" "$URL" -O "$TMPFILE" || {
		error <<< "Could not create login token. Make sure your APIKEY is correct."
		exit
	}
	GSLT="$(cat "$TMPFILE" | jq -r .response.login_token)"
	rm "$TMPFILE"
	[[ $GSLT ]] && echo "$GSLT" > "$SAH_TOKEN_FILE"
}

SteamAPIHelper::handleGSLT () {
	[[ $GSLT ]] && return
	SteamAPIHelper::vars
	[[ $APIKEY ]] || {
		debug <<< "Skipping GSLT generation as no Steam Web API key is set."
		return
	}
	SteamAPIHelper::checkExistingToken || SteamAPIHelper::getNewToken
	true
}
