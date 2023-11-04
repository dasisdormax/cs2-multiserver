#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# The caller script in "$INSTANCE_DIR/msm.d/tmp/server-control.sh" sets the
# following variables:
#    APP
#    THIS_DIR
#    INSTANCE

. "$THIS_DIR/common.sh"

main () {

: Utils

out <<-EOF >&3



	====================================================================

	                       **MSM Server Control**
	                       ----------------------

	Current time:   $(date)
	Log file:       $MSM_LOGFILE

	====================================================================

EOF

info <<-EOF
	This program will control the **$APP** server and react to events
	such as server crashes, pending updates and user commands.
EOF




################################## LOAD MODULES ##################################

: AddonEngine

::init

::add Core.Setup
::add Core.Instance
::add Core.Wrapper

::loadApp
::update




##################################################################################
############################### PROGRAM STARTS HERE ##############################
##################################################################################

Core.Setup::loadConfig
Core.Instance::select

############ STATES ############
# - UPDATING                   #
# - LAUNCHING                  #
# - RUNNING                    #
# - STOPPING FOR UPDATE        #
# - STOPPING                   #
# - STOPPED                    #
################################
STATE="UPDATING"

while [[ $STATE != "STOPPED" ]]; do

	case "$STATE" in

		( UPDATING )
			if Core.Wrapper::isStopRequested; then
				info <<< "Stopping ..."
				STATE="STOPPED"
			elif Core.Wrapper::isUpdating; then
				info <<< "Waiting for updates to finish ..."
				inotifywait -qq -t $(( 21600 - TIME_DIFF )) -e close_write,delete_self "$INSTALL_DIR/msm.d/update" "$TMPDIR"
				sleep .1
				continue
			else
				STATE="LAUNCHING"
			fi
			;;

		( LAUNCHING )
			info <<< "Launching $APP server ..."
			rm -f "$TMPDIR/server.exit-code"
			Core.Wrapper::launchServer "$@"
			STATE="RUNNING"
			;;

		( RUNNING )
			# Perform ALL the checks
			if Core.Wrapper::isStopRequested; then 
				info <<< "Stopping ..."
				Core.Wrapper::shutdownServer
				STATE="STOPPED"
				continue
			fi
			
			if Core.Wrapper::isUpdating; then
				info <<< "Stopping the server for an update ..."
				Core.Wrapper::stopServerForUpdate
				STATE="UPDATING"
				continue
			fi

			errno="$( cat "$TMPDIR/server.exit-code" 2>/dev/null )"
			if [[ $errno ]]; then
				info <<< "Server exited with exit code $errno."

				if (( $errno )); then
					log <<< "Relaunching server due to a crash ..."
					STATE="LAUNCHING"
				elif Core.Wrapper::isUpdating; then
					STATE="UPDATING"
				else
					STATE="STOPPED"
				fi
			fi

			# Wait for stop/update commands or the server exiting
			# Regularly check if something has happened
			if [[ $STATE == "RUNNING" ]]; then
				inotifywait -qq -t 300 -e close_write,delete_self "$INSTALL_DIR/msm.d" "$TMPDIR"
				continue
			fi
			;;

	esac

	debug <<< "Current State: >>> $STATE"

done

info <<< "Server Stopped. Exiting ..."

} # end function main
