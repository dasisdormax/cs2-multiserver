#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.BaseInstallation::registerCommands () {
	simpleCommand "Core.BaseInstallation::requestUpdate" update install
	simpleCommand "Core.BaseInstallation::requestRepair" repair validate
	oneArgCommand "Core.BaseInstallation::cloneFrom" clone
}


Core.BaseInstallation::applyPermissions() {
	App::applyInstancePermissions 2>/dev/null

	chmod -R o-rx "$TMPDIR"
	chmod -R o-rx "$LOGDIR"
}




########################### CREATING A BASE INSTALLATION ##########################

Core.BaseInstallation::isExisting () {
	Core.Instance::select
	Core.Instance::isBaseInstallation
}


# creates a base installation in the directory specified by $INSTALL_DIR
Core.BaseInstallation::create () (

	Core.BaseInstallation::isExisting && return

	Core.Instance::isValidDir || {
		warning <<-EOF
			The directory **$INSTALL_DIR** is non-empty, creating a base
			installation here may cause data to be **LOST or LEAKED**!

			Please backup all important files before proceeding!
		EOF
		sleep 2
		promptN || return
	}

	# Create base installation directory
	mkdir -p "$INSTALL_DIR" && [[ -w "$INSTALL_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$INSTALL_DIR**!"
		return
	}

	# Delete old configuration
	rm -rf "$INSTALL_DIR/msm.d" 2>/dev/null

	# Create new configuration
	mkdir -p "$INSTALL_DIR/msm.d"
	echo $APP > "$INSTALL_DIR/msm.d/app"
	touch "$INSTALL_DIR/msm.d/is-admin" # Mark as base installation

	# Create temporary and logging directories
	mkdir -p -m o-rwx "$TMPDIR"
	mkdir -p -m o-rwx "$LOGDIR"
)


# Clone the base installation from a different machine
# Takes the remote user to copy from in ssh format (user@host)
#
# TODO: test this!!!
Core.BaseInstallation::cloneFrom () {

	[[ $1 ]] || return

	log <<< ""
	requireAdmin || return

	# TODO: Display a warning if the server is already installed

	log <<< "Loading $APP server settings from $1 ..."

	# Get remote install dir
	REMOTE_DIR="$(
		unset INSTALL_DIR
		eval "$(ssh $1 MSM_REMOTE=1 APP=$APP "$THIS_COMMAND" print-config |
				grep ^INSTALL_DIR= )"
		echo "$INSTALL_DIR"
	)"

	[[ $REMOTE_DIR ]] || error <<-EOF || return
			Could not load the configuration of $1! Please make
			sure that your base installation is set up properly on
			that machine!
		EOF

	# Save host:dir to base installation configuration
	echo "$1:$REMOTE_DIR" > "$INSTALL_DIR/msm.d/cloned-from"

	ACTION="update" Core.BaseInstallation::startUpdate
}


Core.BaseInstallation::updateFromClone () {

	log <<< ""
	requireAdmin || return

	log <<< "Cloning Base Installation (this may take a while) ..."

	local SOURCE="$(cat "$INSTALL_DIR/msm.d/cloned-from")"
	if
		rsync -rlptz --info=progress2 --no-inc-recursive \
		--exclude="/msm.d/*" "$SOURCE/" "$INSTALL_DIR"
	then
		success <<< "The server files have been cloned successfully."
	else
		error <<< "Error cloning the server files! (rsync exited with code $?)"
	fi
}




####################### UPDATE AND INSTALLATION HANDLING #######################

requireUpdater () {
	requireAdmin || return
	App::isUpdaterInstalled || error <<-EOF
		The updater for $APP is not installed!

		Install the updater using **$THIS_COMMAND setup**.
	EOF
}


Core.BaseInstallation::requestRepair () {
	ACTION="repair" Core.BaseInstallation::startUpdate
}


Core.BaseInstallation::requestUpdate () {

	log <<< ""
	requireUpdater || return

	########## Check if an update is available at all

	log <<< "Checking for updates ..."

	Core.BaseInstallation::isUpToDate && {
		info <<< "The base installation is already up to date."
		return
	}

	info <<< "The base installation needs to be updated!"

	ACTION="update" Core.BaseInstallation::startUpdate
}


Core.BaseInstallation::isUpToDate () {
	if [[ -e "$INSTALL_DIR/msm.d/cloned-from" ]]; then
		# get timestamp of msm.d/app over ssh
		local SOURCE="$(cat "$INSTALL_DIR/msm.d/cloned-from")"
		local REMOTE_HOST="${SOURCE%%:*}"
		local REMOTE_DIR="${SOURCE#*:}"
		local REMOTE_TIME="$(ssh "$REMOTE_HOST" date -r "$REMOTE_DIR/msm.d/app" +%s)"
		local LOCAL_TIME="$(date -r "$INSTALL_DIR/msm.d/app" +%s)"
		(( LOCAL_TIME > REMOTE_TIME ))
	else
		App::isUpToDate
	fi
}


stopAllInstances () {
	########## Tell running instances that the update is starting soon

	umask o+rx
	local UPDATE_TIME=$(( $(date +%s) + $UPDATE_WAITTIME ))
	echo $UPDATE_TIME > "$INSTALL_DIR/msm.d/update"

	########## Stop running instances

	if Core.Instance::isRunnableInstance; then
		local isRunning=
		local instances="$(Core.Instance::listInstances)";
		for inst in "" $instances; do
			[[ $isRunning ]] && break
			(
				INSTANCE=$inst
				Core.Instance::select
				Core.Server::isRunning
			) && isRunning=1
		done
		[[ $isRunning ]] || return
		
		log <<< "Waiting $UPDATE_WAITTIME seconds for running instances to stop ..."
		while (( $(date +%s) < $UPDATE_TIME )); do 
			sleep 1;
		done
		log <<< ""
	fi
}


# Starts an update or repair of the base installation
# Note: this requires $ACTION variable to be set to either 'update' or 'repair'
Core.BaseInstallation::startUpdate () (

	log <<< ""
	requireUpdater || return

	stopAllInstances

	########## Done waiting, perform the update now.

	log <<< "Performing update/installation NOW."

	# if this is a clone, update from that host instead of the app updater
	# Note: a repair action will always use the app updater
	if [[ -e "$INSTALL_DIR/msm.d/cloned-from" && $ACTION = update ]]; then
		Core.BaseInstallation::updateFromClone
	else
		App::performUpdate
	fi
	local errno=$?

	########## Update timestamp on app file, so clients know that files may have changed

	log <<< ""
	log <<< "Finalizing and applying permissions ..."
	rm "$INSTALL_DIR/msm.d/update" 2>/dev/null
	touch "$INSTALL_DIR/msm.d/app"
	Core.BaseInstallation::applyPermissions

	if (( $errno )); then
		error <<-EOF
			${ACTION^} failed. For more information, see the log file
			**$UPDATE_LOGFILE**.
		EOF
	else
		success <<< "${ACTION^} of your $APP server completed successfully!"
	fi

	return $errno
)
