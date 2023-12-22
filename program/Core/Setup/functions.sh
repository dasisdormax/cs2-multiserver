#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.Setup::registerCommands () {
	simpleCommand "Core.Setup::beginSetup" setup
	simpleCommand "Core.Setup::printConfig" print-config
}




################################ CONFIG HANDLING ################################

requireConfig () {
	Core.Setup::validateConfig || error <<-EOF
		No valid configuration found!

		Create a new configuration using **$THIS_COMMAND setup**.
	EOF
}


requireAdmin () {
	requireConfig || return
	[[ $USER == $ADMIN ]] || error <<-EOF
		The user **$ADMIN** controls the base installation exclusively
		and is the only one who can perform actions on it!
	EOF
}


Core.Setup::loadConfig () {
	if ! .conf "$APP/cfg/defaults.conf"; then
		# Try migrating from older MSM versions
		.conf "cfg/app-$APP.conf" || return;
		[[ -O $USER_DIR ]] && Core.Setup::writeConfig && mv "$USER_DIR/cfg/app-$APP.conf"{,.old}
	fi
	Core.Setup::validateConfig
}


# load msm configuration file of the given user
Core.Setup::loadConfigOf () {
	USER_DIR="$(eval echo ~$1)/msm.d" Core.Setup::loadConfig
}


# Check the current configuration variables for correctness and plausibility
Core.Setup::validateConfig () {
	# Require admin variable
	[[ $ADMIN ]] || error <<< "variable \$ADMIN is not defined!" || return

	# Check base installation directory
	[[ $INSTALL_DIR                       ]] || error <<-EOF || return
			variable \$INSTALL_DIR is not defined!
		EOF

	[[ -r $INSTALL_DIR && -x $INSTALL_DIR ]] || error <<-EOF || return
			The base installation directory **$INSTALL_DIR**
			is not accessible!
		EOF

	INSTANCE_DIR="$INSTALL_DIR" Core.Instance::isBaseInstallation \
											 || error <<-EOF || return
			The directory **$INSTALL_DIR** is not a
			valid base installation for $APP!
		EOF
}


Core.Setup::writeConfig () {
	if Core.Setup::validateConfig; then
		if mkdir -p "$CFG_DIR" && Core.Setup::printConfig > "$CFG"; then
			[[ $USER != $ADMIN ]] || make-readable "$CFG"
		else
			fatal <<-EOF
				Error writing the configuration to **$CFG**!
				You may lack the necessary permissions to access the file!
			EOF
		fi
	else
		error <<< "Invalid configuration!"
	fi
}


Core.Setup::printConfig () {
	cat <<-EOF
		#! /bin/bash
		# This is a configuration file for Multi Server Manager with APP=$APP

		__ADMIN__=$ADMIN
		INSTALL_DIR="$INSTALL_DIR"
		DEFAULT_INSTANCE="$DEFAULT_INSTANCE"
		MSM_ADDONS="$MSM_ADDONS"
	EOF

	try App::printAdditionalConfig
	true
}




################################# INITIAL SETUP #################################

Core.Setup::beginSetup () {
	out <<< ""

	# Check, if config exists already
	[[ -e "$CFG" ]] && {
		info <<-EOF
			The config file **$CFG** already exists!
			If you want to start over, delete that file and run this command again.
		EOF
		return
	}

	out <<-EOF
		-------------------------------------------------------------------------------
						 CS2 Multi-Mode Server Manager - Initial Setup
		-------------------------------------------------------------------------------

		It seems like this is the first time you use this script on this machine.
		Before advancing, be aware of a few things:

		>>  The configuration files will be saved in the directory:
				**$CFG_DIR**

			Make sure to backup any important data in that location.

	EOF

	promptY || return

	# Create config directory
	mkdir -p "$CFG_DIR" && [[ -w "$CFG_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$CFG_DIR**!"
		return
	}

	ADMIN=$USER
	Core.Setup::setupAsAdmin

	# Succeeds, if we have a valid config at the end
	Core.Setup::loadConfig
}




############################### ADMIN INSTALLATION ##############################

# TODO: make this function smaller
Core.Setup::setupAsAdmin () {

	log <<-EOF

		Basic Setup
		===========

		This assistant will install all remaining dependencies for your
		$APP server and create a basic configuration.  Please follow the
		instructions below.
	EOF

	######### Install App Downloader/Updater

	App::installUpdater || return

	######### Create base installation

	INSTANCE=
	INSTALL_DIR="$USER_DIR/$APP/base"
	until Core.BaseInstallation::isExisting; do
		bold <<-EOF

			Now, please select the **base installation directory**.  This is the
			directory the server will be downloaded to, make sure that there is
			plenty of free space on the disk.

		EOF

		read -r -p "Game Server Installation Directory (default: $USER_DIR/$APP/base) " INSTALL_DIR

		INSTALL_DIR=${INSTALL_DIR:-"$USER_DIR/$APP/base"}
		INSTALL_DIR="$(eval echo "$INSTALL_DIR")"   # expand tilde and stuff
		INSTALL_DIR="$(readlink -m "$INSTALL_DIR")" # get absolute directory

		Core.BaseInstallation::create
	done

	# Final Steps
	Core.Instance::select
	App::finalizeInstance
	Core.BaseInstallation::applyPermissions

	# Create Config and make it readable
	mkdir -p -m o-rwx "$TMPDIR" "$LOGDIR" "$INSTCFGDIR"
	# Create the initial instance configuration files
	cp -rn "$APP_DIR"/cfg/* "$INSTCFGDIR" 2>/dev/null

	MSM_ADDONS=""
	Core.Setup::writeConfig && {
		log <<< ""
		success <<-EOF
			Basic Setup Complete!

			Execute **$THIS_COMMAND install** to install or update the actual game files.
			Of course, you can also copy the files from a different location.

			Use **$THIS_COMMAND @name create** to create a new server instance out of
			your base installation.  Each instance can be configured independently and
			multiple instances can run simultaneously.
		EOF
	}
}
