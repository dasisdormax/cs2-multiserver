#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




############################### COMMON FUNCTIONS ################################

# override dot builtin: execute a handler (either a .sh-file or .sh-files in a directory)
# Further parameters are passed to the executed scripts
. () {
	local cmd="${1%%.sh}" # Strip .sh extension
	# Try executing file or file.sh (depending on extension) otherwise execute sh-files in directory
	if [[ $cmd =~ \.[^/]*$ ]]; then
		.file "$cmd"    "${@:2}" && return
	else
		.file "$cmd.sh" "${@:2}" && return
	fi
	.dir "$cmd" "${@:2}"
}


# Execute all .sh-files inside a given directory
# Further parameters are passed to the executed scripts
#
# Returns
#   true,  if all files in the directory $1 could be executed
#   false, - if $1 is no directory or contains no .sh files
#          - if errors occured during the execution of any file
.dir () {
	[[ -d $1 ]] && {
		for file in "$1"/*.sh; do
			.file "$file" "${@:2}" || return
		done
	}
}


# Execute a file and set the context for the colon function
# Further parameters are passed to the executed scripts
.file () { [[ -f $1 ]] || return 127 && builtin . "$@"; }


# .conf function: execute a config file, preferring user config over global config
# NOTE: A global config file can return any error code except 127 (file not found)
# >     to prevent the execution of user config files
.conf () {
	.file "$THIS_DIR/$@"
	CODE=$?
	if (( ! CODE || CODE == 127 )); then
		.file "$USER_DIR/$@"
		(( $? == 127 && CODE == 127 )) && return 127
	fi
	applyDefaults
}


# override colon builtin: execute a file relative to the current file's base directory
# Further parameters are passed to the executed scripts
: () {
	CURR_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[1]}")")"
	. "$CURR_DIR/$@"
}


# apply default values for variables
applyDefaults () {
	local target
	local source
	for source in ${!__*}; do
		[[ $source =~ __$ ]] || continue
		# Strip underscores from varname
		target=${source%__}
		target=${target#__}
		[[ ! ${!target} ]] && declare -g $target="${!source}"
		unset $source
	done
}




############################### COMMON VARIABLES ################################


UPDATE_WAITTIME=75
USER=$(whoami) # just in case
USER_DIR="$HOME/msm.d"
