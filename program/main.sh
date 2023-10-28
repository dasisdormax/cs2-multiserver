#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




main () {

: Utils # Enable output functions and logging

out <<-EOF >&3



	========================================================================

	                      **CS2 Multi Server Manager**
	                      ----------------------------

	  Current time:   $(date)
	  Log file:       $MSM_LOGFILE
	  Commands:       $@

	========================================================================

EOF




############################### CHECK DEPENDENCIES ###############################

# Check required programs
local programs="sed awk tmux wget tar unbuffer readlink inotifywait"
local program
for program in $programs; do
	[[ -x $(which $program) ]] ||
		fatal <<< "The program **$program** could not be found on your system!" || return
done




################################## LOAD MODULES ##################################

: AddonEngine

::init

::add Core.CommandLine
::add Core.Setup
::add Core.BaseInstallation
::add Core.Instance
::add Core.Server

::loadApp
::update




# TODO: add config and instance checks to all functions that require
#       them - arguments such as help should work independently

if ! (( $# )); then
	Core.CommandLine::usage
	echo
	return
fi




# Use $DEFAULT_INSTANCE variable from configuration file
# if unset, the default instance is the base installation

Core.Setup::loadConfig
::loadAddons
INSTANCE="$DEFAULT_INSTANCE" Core.CommandLine::parseArguments "$@"

local errno=$?
# Insert space before ending the program (if it is not a remote command)
[[ $MSM_REMOTE ]] || echo
return $?

} # end function main
