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




################################# SETUP HELPERS #################################

Core.Setup::importFrom () {
	local IMPORT_FROM=$1
	out <<< ""
	out <<< "Trying to import the configuration of user **$IMPORT_FROM** ..."

	# Try importing that user's configuration
	Core.Setup::loadConfigOf $IMPORT_FROM
	local CODE=$?
	# If the config file does not exist, try switching to that user
	if (( CODE == 127 )); then
		warning <<-EOF
			Import from user **$IMPORT_FROM** failed. That user either has no configuration
			to import from, or that configuration is not accessible. You may, though, switch
			to that user and fix these problems.

			You may need to confirm switching users with your sudo password. (CTRL-C to cancel)

		EOF

		sudo -iu $IMPORT_FROM \
			MSM_LOGFILE="$MSM_LOGFILE" MSM_DEBUG=$MSM_DEBUG __ADMIN__=$ADMIN \
			"$THIS_COMMAND" setup ||
		{
			out <<< "Cancelled the import from user $IMPORT_FROM ..."
			return 1
		}

		# Try importing again with those changes made
		Core.Setup::loadConfigOf $IMPORT_FROM
		CODE=$?
	fi

	(( CODE )) && error <<-EOF && return $CODE
			The configuration of user $IMPORT_FROM contains errors!
		EOF

	if [[ $ADMIN != $IMPORT_FROM ]]; then
		info <<-EOF
			The configuration of user $IMPORT_FROM refers to user $ADMIN.
			We will now try to import that user's configuration instead ...
		EOF
		Core.Setup::importFrom $ADMIN;
		return
	fi

	Core.Setup::writeConfig
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

		>>  For multi-user setups, this script, located at
		        **$THIS_SCRIPT**
		    must be readable for all users.
	EOF

	promptY || return

	# Create config directory
	mkdir -p "$CFG_DIR" && [[ -w "$CFG_DIR" ]] || {
		fatal <<< "No permission to create or write the directory **$CFG_DIR**!"
		return
	}

	# Ask the user if they wish to import a configuration
	ADMIN=${ADMIN-$__ADMIN__}
	if [[ ! $ADMIN ]]; then
		log <<-EOF

			Importing configurations
			========================
		EOF
		fmt -w67 <<-EOF | indent

			Instead of creating a new configuration, you may also import the settings
			from a different user on this system.  This allows you to use that user's
			game server installation as a base for your own instances, without having
			to download the server files again.

			If you wish to import the settings from another user, enter their name
			below. Otherwise, hit enter to create your own configuration.
		EOF
	fi

	local SUCCESS=
	until [[ $SUCCESS ]]; do
		if [[ ! $ADMIN ]]; then
			echo
			echo "Please enter the user to import the configuration from.  Leave empty"
			echo "to skip importing configurations, press CTRL-C to exit."
			echo
			read -p "> Import configuration from? " -r ADMIN

			if [[ $ADMIN ]]; then
				debug <<< "Selected to import from user **$ADMIN**."
			else
				ADMIN=$USER
				debug <<< "Skipping import and starting admin setup."
			fi
		fi

		[[ $ADMIN == $USER ]] && { Core.Setup::setupAsAdmin; return; }

		if Core.Setup::importFrom $ADMIN; then
			success <<< "The configuration of user **$ADMIN** has been imported successfully!"
			local SUCCESS=1
		else
			warning <<< "Import failed! Please specify a different user."
			ADMIN=
		fi
	done

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
			plenty of free space on the disk.  Be aware that this directory will
			be made **public readable**, so other users on the system can create
			server instances based on it.

		EOF

		read -r -p "Game Server Installation Directory (default: $USER_DIR/$APP/base) " INSTALL_DIR

		INSTALL_DIR=${INSTALL_DIR:-"$USER_DIR/$APP/base"}
		INSTALL_DIR="$(eval echo "$INSTALL_DIR")"   # expand tilde and stuff
		INSTALL_DIR="$(readlink -m "$INSTALL_DIR")" # get absolute directory

		Core.BaseInstallation::create
	done

	# Final Steps
	App::finalizeInstance
	Core.BaseInstallation::applyPermissions

	# Create Config and make it readable
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
