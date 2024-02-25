#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




App::isRunnableInstance () [[ -x $INSTANCE_DIR/$SERVER_EXEC ]]


# files/directories to copy fully 
App::instanceCopiedFiles () { cat <<-EOF ; }
	game/csgo/addons
	game/csgo/cfg
	game/csgo/models
	game/csgo/sound
	game/csgo/gameinfo.gi
EOF


# directories, in which the user can put own files in addition to the provided ones
App::instanceMixedDirs () { cat <<-EOF ; }
	game/csgo/maps
	game/csgo/maps/cfg
	game/csgo/maps/soundcache
	game/csgo/logs
	game/csgo/resource/overviews
	game/bin/linuxsteamrt64
EOF


# files/directories which are not shared between the base installation and the instances
App::instanceIgnoredFiles () { cat <<-EOF ; }
	game/csgo/addons
	game/csgo/replays
EOF


App::finalizeInstance () (
	[[ $INSTANCE_DIR -ne $INSTALL_DIR ]] && {
		# Make sure each instance has its own up-to-date cs2 binary
		rm "$INSTANCE_DIR/$SERVER_EXEC"
		cp "$INSTALL_DIR/$SERVER_EXEC" "$INSTANCE_DIR/$SERVER_EXEC"
	}
	# copy presets from app to user config directory
	mkdir -p "$CFG_DIR/presets"
	cp -n "$APP_DIR"/presets/* "$CFG_DIR/presets"
)


App::applyInstancePermissions () {
	# Remove read privileges for files that may contain sensitive data
	# (such as passwords, IP addresses, etc)
	
	chmod -R o-r "$INSTANCE_DIR/msm.d/cfg"
	chmod o-r "$INSTANCE_DIR/game/csgo/cfg/autoexec.cfg"
	chmod o-r "$INSTANCE_DIR/game/csgo/cfg/server.cfg"
	true
} 2>/dev/null


App::varsToPass () { cat <<-EOF ; }
	APP
	MODE
	TEAM_T
	TEAM_CT
	IP
	PORT
	TV_PORT
	PASS
	USE_RCON
	RCON_PASS
	SLOTS
	ADMIN_SLOTS
	TAGS
	TITLE
EOF
