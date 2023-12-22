#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




App::validateGSLT () {
	[[ $GSLT ]] && return
	debug <<< "Launching CS2 with no Game Server Login Token (GSLT) specified ..."
}


App::buildLaunchCommand () {
	# Read general config
	.file "$INSTCFGDIR/server.conf"

	# As "old" config files immediately generate all files and
	# the launch command, we have nothing more to do
	[[ $LAUNCH_CMD ]] && return

	# Load preset (such as gamemode, maps, ...)
	PRESET="${PRESET-"$__PRESET__"}"
	[[ $PRESET ]] && .file "$CFG_DIR/presets/$PRESET.conf"
	applyDefaults

	# Load GOTV settings
	.conf "$APP/cfg/$INSTANCE_SUFFIX/gotv.conf"

	######## Check GSLT ########
	::hookable App::validateGSLT

	######## PARSE MAPS AND MAPCYCLE ########

	# Convert MAPS to array
	MAPS=( ${MAPS[*]} )
	# Workshop maps are handled in generateServerConfig

	# Generate Server and GOTV titles
	TITLE=$(title)
	TITLE=${TITLE::64}
	TAGS=$(tags)
	TV_TITLE=$(tv_title)

	(( TV_ENABLE )) || unset TV_ENABLE

	######## GENERATE SERVER CONFIG FILES ########
	App::generateServerConfig || return

	MAP=${MAP:-${MAPS[0]//\\//}}

	######## GENERATE LAUNCH COMMAND ########
	LAUNCH_ARGS=(
		-dedicated
		-console
		$USE_RCON
		${TICKRATE:+-tickrate $TICKRATE} # Likely has no effect with CS2 tickless
		-ip $IP
		-port $PORT
		${WAN_IP:++net_public_adr "'$WAN_IP'"}

		${SV_OCCLUDE_PLAYERS:++sv_occlude_players "$SV_OCCLUDE_PLAYERS"}

		+game_type $GAMETYPE
		+game_mode $GAMEMODE
		+mapgroup $MAPGROUP
		+map $MAP

		${TV_ENABLE:+
			+tv_enable 1
			+tv_port "$TV_PORT"
			+tv_maxclients "$TV_MAXCLIENTS"
		} # GOTV Settings

		${TV_RELAY:+
			+tv_relay "$TV_RELAY"
			+tv_relaypassword "$TV_RELAYPASS"
		} # GOTV RELAY SETTINGS

		${APIKEY:+-authkey $APIKEY}

		+exec autoexec.cfg
	)

	LAUNCH_DIR="$INSTANCE_DIR/game/bin/linuxsteamrt64"
	LAUNCH_CMD="$(quote "./cs2" "${LAUNCH_ARGS[@]}")"
}


# Announces an update which will cause the server to shut down
App::announceUpdate () {
	tmux-send -t ":$APP-server" <<-EOF
		say "This server is shutting down for an update soon. See you later!"
	EOF
}

# Ask the server to shut down
App::shutdownServer () {
	tmux-send -t ":$APP-server" <<-EOF
		quit
	EOF
}

App::killServer () {
	# CS2 survives a hangup of the launching terminal, so we kill the process owning the socket directly
	local PID=$(ss -Hulpn sport = :$PORT | grep -Eo 'pid=[0-9]+')
	[[ $PID ]] || return
	PID=${PID#*=}
	debug <<< "Killing server with pid = $PID ..."
	kill $PID
}