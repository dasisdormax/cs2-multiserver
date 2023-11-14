#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




############################ STEAMCMD INSTALLATION ############################

App::isUpdaterInstalled () [[ -x $HOME/Steam/steamcmd/steamcmd.sh ]]


App::installSteamCMD () (

	# Skip installation if SteamCMD is already installed
	App::isUpdaterInstalled && return

	STEAMCMD_DIR="$HOME/Steam/steamcmd"
	out <<-EOF

		Installing **SteamCMD**, which is required to install and update
		the game server, to directory **$STEAMCMD_DIR** ...
	EOF

	# Create the directory
	mkdir -p "$STEAMCMD_DIR" && [[ -w $STEAMCMD_DIR ]] || {
		fatal <<< "No permission to create or write the directory **$STEAMCMD_DIR**!"
		return
	}
	cd "$STEAMCMD_DIR"

	# Warn, if the directory already contains files
	[[ $(ls -A) ]] && {
		warning <<-EOF
				The directory **$STEAMCMD_DIR** is non-empty, installing
				SteamCMD to this location may cause **LOSS OF DATA**!

				Please backup all important files before proceeding!
			EOF
		sleep 2
		promptN || return
	}

	log <<< ""
	log <<< "Downloading SteamCMD ..."
	until wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"; do
		log <<< "  - Download failed. Retrying ..."; sleep 5; done

	log <<< "Extracting Archive ..."
	tar xzf steamcmd_linux.tar.gz
	rm steamcmd_linux.tar.gz &> /dev/null

	[[ -x steamcmd.sh ]] || error <<< "SteamCMD installation failed!" || return

	log <<< "Self-updating ..."
	log-cmd ./steamcmd.sh +quit
	log <<< ""

	log <<< "Linking Steam client libraries ..."
	mkdir -p "$HOME/.steam/sdk64"
	local dst="$HOME/.steam/sdk64/steamclient.so"
	if [[ ! -r $dst ]]; then
		rm -f "$dst"
		local src="$HOME/Steam/steamcmd/linux64/steamclient.so"
		[[ -e $src ]] || src="$HOME/.steam/steamcmd/linux64/steamclient.so"
		ln -s "$src" "$dst" >&3 2>&1
	fi

	success <<< "SteamCMD installed successfully!"
)


App::installUpdater () {

	App::installSteamCMD || return

	# Once SteamCMD is installed, get the username and perform a first login
	[[ $STEAM_USERNAME ]] && return
	
	out <<-EOF
		
		To install and update the CS2 game server, you need to log in to your
		Steam account.
	EOF

	local SUCCESS=
	until [[ $SUCCESS ]]; do
		out <<-EOF

			Please enter your Steam account's username (the one you log in with, not
			your display name).

		EOF
		read -p "> Your steam username: " -r STEAM_USERNAME
		[[ $STEAM_USERNAME ]] || continue
		out <<-EOF

			We will now try to log you in with that username. Steam will probably ask
			you for your password and Steam Guard code.

		EOF

		local STEAMCMD_SCRIPT="$(mktemp)"
		cat <<-EOF > "$STEAMCMD_SCRIPT"
			login $STEAM_USERNAME
			quit
		EOF
		log-cmd "$HOME/Steam/steamcmd/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT"
		log <<< ""
		local steamcfg="$HOME/Steam/config/config.vdf"
		[[ -r $steamcfg ]] || steamcfg="$HOME/.steam/config/config.vdf"
		grep "\"$STEAM_USERNAME\"" "$steamcfg" >/dev/null 2>&1 && SUCCESS=1
	done

	success <<< "Steam login successful!"
}


App::printAdditionalConfig () {
	echo "STEAM_USERNAME=$STEAM_USERNAME"
}


# Check, if an update to the CS2 Base Installation is available
# returns 0, if the most current version is installed
#         1, if an update is available
#         2, if the game is not installed yet
#         9, if checking for the update failed
App::isUpToDate () {

	# variables
	local APPMANIFEST="$INSTALL_DIR/steamapps/appmanifest_730.acf"

	# If game is not installed yet, skip checking
	[[ -e $APPMANIFEST ]] || return 2

	# Clear cache
	rm ~/Steam/appcache/appinfo.vdf 2>/dev/null

	local STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	local STEAMCMD_OUT="$TMPDIR/steamcmd-out"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		login $STEAM_USERNAME
		app_info_update 1
		app_info_print 730
		quit
	EOF

	rm "$STEAMCMD_OUT" 2>/dev/null
	# Get current build id through SteamCMD
	MSM_LOGFILE="$STEAMCMD_OUT" log-cmd "$HOME/Steam/steamcmd/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT" >&3

	local oldbuildid=$(cat "$APPMANIFEST" | grep "buildid" | awk '{ print $2 }')
	local newbuildid=$(
			cat "$STEAMCMD_OUT" |
			sed 's/\r$//' |
			sed -n '/^"730"$/        ,/^}/       p' |
			sed -n '/^\t\t"branches"/,/^\t\t}/   p' |
			sed -n '/^\t\t\t"public"/,/^\t\t\t}/ p' |
			grep "buildid" | awk '{ print $2 }'
		)

	(( $? == 0 )) || error <<< "Could not search for updates!" || return 9

	debug <<< "Installed build is $oldbuildid, most recent build is $newbuildid."

	[[ $oldbuildid == $newbuildid ]]
}


# Actually perform a requested update
# Takes the action (either update or repair) as parameter
App::performUpdate () (

	# Work in base installation directory
	INSTANCE=
	Core.Instance::select

	# Prepare SteamCMD script
	STEAMCMD_SCRIPT="$TMPDIR/steamcmd-script"
	MSM_LOGFILE="$LOGDIR/$(timestamp)-$ACTION.log"
	cat <<-EOF > "$STEAMCMD_SCRIPT"
		force_install_dir "$INSTALL_DIR"
		login $STEAM_USERNAME
		app_update 730 $( [[ $ACTION == repair ]] && echo "validate" )
		quit
	EOF

	local tries=5
	local try=0
	local code=1
	while (( $code && ++try <= tries )); do
		log <<-EOF | catinfo

			####################################################
			# $(printf "[%2d/%2d] %40s" $try $tries "$(date)") #
			# $(printf "%-48s" "Trying to $ACTION the game using SteamCMD ...") #
			####################################################

		EOF

		log-cmd "$HOME/Steam/steamcmd/steamcmd.sh" +runscript "$STEAMCMD_SCRIPT"
		log <<< ""

		egrep "Success! App '730'.*(fully installed|up to date)" \
		      "$MSM_LOGFILE" > /dev/null                   && local code=0

	done

	out <<-EOF

		Logs have been written to **$MSM_LOGFILE**"
	EOF

	# App::applyInstancePermissions

	return $code
)
