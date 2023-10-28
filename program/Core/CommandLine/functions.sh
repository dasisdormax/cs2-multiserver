#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.CommandLine::registerCommands () {
	simpleCommand "Core.CommandLine::usage" help --help -h /? usage
	simpleCommand "about-this-program" info about license
}




################################## USAGE INFO ##################################

# usage: display all the possible commands and a short explanation of what they do
# 
# TODO: Allow addons to inject their usage information into this function
Core.CommandLine::usage () { bold <<EOF

Usage: **$THIS_COMMAND** < commands >

$(printf "\x1b[36m%s\x1b[m"   "**GENERAL COMMANDS:**")
    usage    > Display this help message
    info     > About this script / copyright and license information

$(printf "\x1b[36m%s\x1b[m"   "**INSTANCE SELECTION:**")
    @...     > Select the server instance to apply the following commands on.
             > If no name is given, work on the base installation instead.

    By default, the base installation is used. You may specify a different
    \$DEFAULT_INSTANCE in your config file.

$(printf "\x1b[36m%s\x1b[m"   "**INSTANCE-SPECIFIC COMMANDS:**")
    create   > Create a new server instance
    start | stop | restart
             > Start/Stop/Restart given server instance (using tmux)
    status   > Check whether the server is currently running
    console  > Attach (connect) to the server's console. While inside, press
             > CTRL-D to detach (return to outside) without killing the server

$(printf "\x1b[36m%s\x1b[m"   "**ADMINISTRATION COMMANDS:** working on the base installation")
    setup    > Configure this program and install dependencies
    update   > Install/Update the game server
    validate > Repair broken/missing game files

Commands will be executed in the order they are given. If a command fails,
subsequent commands will not be executed.
EOF
}




############################# COMMAND LIST HELPERS #############################

Core.CommandLine::loadModuleCommands () {
	unset       SIMPLE_COMMANDS  ONEARG_COMMANDS  GREEDY_COMMANDS
	declare -gA SIMPLE_COMMANDS  ONEARG_COMMANDS  GREEDY_COMMANDS

	local m
	for m in $Modules; do
		try $m::registerCommands
	done
}


# Add a simple command (takes no arguments)
# Assign function $1 to commands $...
simpleCommand () {
	local c
	for c in ${@:2}; do
		SIMPLE_COMMANDS[$c]="$1"
	done
}


# Adds a command that takes exactly one argument
oneArgCommand () {
	local c
	for c in ${@:2}; do
		ONEARG_COMMANDS[$c]="$1"
	done
}


# Adds a greedy command that takes all remaining arguments, until
# the next instance is selected (use @@ to stay on the same instance)
greedyCommand () {
	local c
	for c in ${@:2}; do
		GREEDY_COMMANDS[$c]="$1"
	done
}




######################### ACTUAL COMMAND LINE PARSING ##########################

Core.CommandLine::parseArguments () {
	unset INSTANCE
	local ARGS=( )
	while [[ $1 ]]; do
		if [[ $1 =~ ^@ ]]; then
			::hookable Core.CommandLine::exec "${ARGS[@]}"
			[[ ! ${1:1} =~ @ ]] && INSTANCE="${1:1}"
			ARGS=( )
		else
			ARGS+=( "$1" )
		fi
		shift
	done
	::hookable Core.CommandLine::exec "${ARGS[@]}"
}


# TODO: Allow addons to define their own arguments and corresponding actions
Core.CommandLine::exec () (

	[[ $@ ]] || return

	INSTANCE=${INSTANCE-"$DEFAULT_INSTANCE"}
	Core.Instance::select

	out <<-EOF >&3



		==~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~==

		    Executing the following commands on **$INSTANCE_TEXT**:
		        $(quote "$@")
	EOF

	Core.CommandLine::execRemotely "$@" && return

	Core.CommandLine::loadModuleCommands

	while [[ $1 ]]; do ################ BEGIN LOOP ################

		out <<-EOF >&3


			>>>>> Currently parsing argument: **$1**
		EOF

		if   [[ ${SIMPLE_COMMANDS[$1]} ]]; then
			debug <<< "Executing ${SIMPLE_COMMANDS[$1]}"
			${SIMPLE_COMMANDS[$1]}

		elif [[ ${ONEARG_COMMANDS[$1]} ]]; then
			local fun=${ONEARG_COMMANDS[$1]}
			shift
			debug <<< "Executing $fun $1"
			$fun "$1"

		elif [[ ${GREEDY_COMMANDS[$1]} ]]; then
			local fun=${GREEDY_COMMANDS[$1]}
			local args=( )
			while shift; do
				[[ $1 ]] && args+=( "$1" )
			done
			debug <<< "Executing $fun $(quote "${args[@]}")"
			$fun "${args[@]}"

		else
			log <<< ""
			error <<< "Unknown command: **$1**"
		fi

		shift
	done ################ END LOOP ################
)


# Try executing the commands on a remote machine
# fails (exit code 1) if it is a local instance
#
# TODO: Seems to work, but test more!
Core.CommandLine::execRemotely () {
	[[ $INSTANCE && -e "$INSTANCE_DIR/msm.d/host" ]] || return 1

	local HOST="$(cat "$INSTANCE_DIR/msm.d/host")"

	debug <<-EOF
		Switching to machine **$HOST**, which is the
		host of **remote instance @$INSTANCE** ...
	EOF

	ssh -t "$HOST" \
		MSM_REMOTE=1 $(ssh-pass-vars MSM_DEBUG APP $(try App::varsToPass)) \
		"$THIS_COMMAND" @$INSTANCE "$@"

	return 0
}
