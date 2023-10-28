#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




################################ STATUS CHECKS ################################


Core.Wrapper::isUpdating      () {
	[[ -e "$INSTALL_DIR/msm.d/update" ]] || return

	local UPDATE_TIME=$(cat "$INSTALL_DIR/msm.d/update")
	local TIME_DIFF=$(( $(date +%s) - UPDATE_TIME ))
	(( TIME_DIFF < 2160 ))
}


Core.Wrapper::isStopRequested () [[ -e "$TMPDIR/stop" ]]


Core.Wrapper::isServerRunning () [[ $(tmux list-windows) =~ $APP-server ]]




################################ SERVER CONTROL ################################

Core.Wrapper::launchServer () {
	# TODO: allow app-specific modifications
	[[ $INSTALL_DIR/msm.d/app -nt $INSTANCE_DIR/msm.d/app ]] && (
		info <<-EOF
			The base installation has been updated since the last launch.
			Synchronizing ...
		EOF
		cd "$INSTANCE_DIR"
		Core.Instance::symlinkFiles
		App::finalizeInstance
		App::applyInstancePermissions
		touch "msm.d/app"
	)
	tmux new-window -n "$APP-server" /bin/bash "$TMPDIR/server-start.sh"
}


Core.Wrapper::stopServerForUpdate () {
	local DEADLINE=$(cat "$INSTALL_DIR/msm.d/update")
	local TIME_DIFF=$(( DEADLINE - $(date +%s) - 30 ))

	if (( TIME_DIFF > 0 )) && Core.Wrapper::isServerRunning; then
		try App::announceUpdate
		sleep $TIME_DIFF
	fi

	Core.Wrapper::shutdownServer $DEADLINE
}


Core.Wrapper::shutdownServer () {
	local DEADLINE=${1:-$(cat "$TMPDIR/stop")}

	Core.Wrapper::isServerRunning || return
	App::shutdownServer

	while Core.Wrapper::isServerRunning && (( DEADLINE - $(date +%s)  > 5 ))
	do
		sleep 1
	done

	Core.Wrapper::killServer
}


Core.Wrapper::killServer () { tmux kill-window -t ":$APP-server"; } 2>/dev/null
