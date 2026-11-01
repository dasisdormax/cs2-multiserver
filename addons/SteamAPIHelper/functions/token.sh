#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# The first line remains the token for compatibility with existing installations.
# The second line stores the game server Steam ID.
SteamAPIHelper::saveToken () {
	local TOKEN=$1 STEAMID=$2 TEMP
	TEMP="${SAH_TOKEN_FILE}.tmp"
	printf '%s\n%s\n' "$TOKEN" "$STEAMID" > "$TEMP" && mv -f "$TEMP" "$SAH_TOKEN_FILE"
	rm -f "$TEMP"
	GSLT=$TOKEN
}

SteamAPIHelper::getNewToken () {
	local URL DATA MEMO TMPFILE TOKEN STEAMID
	URL=https://api.steampowered.com/IGameServersService/CreateAccount/v1
	MEMO="[cs2-multiserver] $(uname -n), instance @$INSTANCE"
	echo "Creating a new game server with memo '$MEMO'" >&2
	DATA="key=$APIKEY&appid=$SAH_APPID&memo=$MEMO"
	TMPFILE="$(mktemp)" || return 1
	if ! wget -q --post-data "$DATA" "$URL" -O "$TMPFILE"; then
		rm -f "$TMPFILE"
		echo "Could not create a game server account with Steam." >&2
		return 1
	fi
	TOKEN="$(jq -er '.response.login_token | select(type == "string" and length > 0)' "$TMPFILE" 2>/dev/null)" || TOKEN=
	STEAMID="$(jq -er '.response.steamid | select(type == "string" and test("^[0-9]+$") and . != "0")' "$TMPFILE" 2>/dev/null)" || STEAMID=
	rm -f "$TMPFILE"
	if [[ ! $TOKEN || ! $STEAMID ]]; then
		echo "Steam returned an invalid game server account response." >&2
		return 1
	fi
	SteamAPIHelper::saveToken "$TOKEN" "$STEAMID"
}

SteamAPIHelper::checkExistingToken () {
	local STEAMID URL DATA TMPFILE TOKEN
	[[ -r $SAH_TOKEN_FILE ]] || return 1
	GSLT="$(sed -n '1p' "$SAH_TOKEN_FILE")"
	STEAMID="$(sed -n '2p' "$SAH_TOKEN_FILE")"
	[[ $GSLT ]] || return 1

	# Older token files contain no Steam ID. Query the token once to get the Steam ID.
	if [[ ! $STEAMID =~ ^[0-9]+$ || $STEAMID == 0 ]]; then
		TMPFILE="$(mktemp)" || return 0
		URL="https://api.steampowered.com/IGameServersService/QueryLoginToken/v1/?key=$APIKEY&login_token=$GSLT"
		if ! wget -q "$URL" -O "$TMPFILE"; then
			rm -f "$TMPFILE"
			echo "Could not check the game server account. Using the saved token." >&2
			return 0
		fi
		STEAMID="$(jq -er '.response.steamid | select(type == "string" and test("^[0-9]+$") and . != "0")' "$TMPFILE" 2>/dev/null)" || STEAMID=
		rm -f "$TMPFILE"
		if [[ ! $STEAMID ]]; then
			echo "Could not find the Steam ID for the saved token. Creating a new one." >&2
			SteamAPIHelper::getNewToken || echo "Using the saved token." >&2
			return 0
		fi
		SteamAPIHelper::saveToken "$GSLT" "$STEAMID"
	fi

	URL=https://api.steampowered.com/IGameServersService/ResetLoginToken/v1/
	DATA="key=$APIKEY&steamid=$STEAMID"
	TMPFILE="$(mktemp)" || return 0
	if ! wget -q --post-data "$DATA" "$URL" -O "$TMPFILE"; then
		rm -f "$TMPFILE"
		echo "Could not check the game server account. Using the saved token." >&2
		return 0
	fi
	TOKEN="$(jq -er '.response.login_token | select(type == "string" and length > 0)' "$TMPFILE" 2>/dev/null)" || TOKEN=
	if [[ $TOKEN ]]; then
		rm -f "$TMPFILE"
		SteamAPIHelper::saveToken "$TOKEN" "$STEAMID"
		return 0
	fi
	if jq -e '.response | type == "object" and length == 0' "$TMPFILE" >/dev/null 2>&1; then
		rm -f "$TMPFILE"
		echo "The game server account was removed. Creating a new one." >&2
		SteamAPIHelper::getNewToken || echo "Using the saved token." >&2
		return 0
	fi
	rm -f "$TMPFILE"
	echo "Steam returned an unexpected response. Using the saved token." >&2
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
