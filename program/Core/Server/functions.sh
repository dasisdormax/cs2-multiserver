#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




Core.Server::registerCommands () {
	simpleCommand "Core.Server::requestStart" start launch
	simpleCommand "Core.Server::requestStop" stop
	simpleCommand "Core.Server::requestRestart" restart
	simpleCommand "Core.Server::printStatus" status
	simpleCommand "Core.Server::attachToConsole" console attach

	greedyCommand "Core.Server::sendCommand" send exec execute
}




################################# STATUS QUERY #################################

# Returns true, if the server wrapper is running
#               (the server may be running or updating)
Core.Server::isRunning () {
	[[ -e "$SOCKET" ]] && tmux -S "$SOCKET" has-session
} >/dev/null 2>&1


# Returns true, if the server wrapper is running and waits for an update to finish
Core.Server::isUpdating () {
	Core.Server::isRunning && [[ ! $(tmux -S "$SOCKET" list-windows) =~ $APP-server ]]
}




########################### SERVER CONTROL FUNCTIONS ###########################

Core.Server::requestStart () {

	log <<< ""
	requireRunnableInstance || return

	Core.Server::isRunning && info <<-EOF && return
			$INSTANCE_TEXT is already running! Try entering your server's
			console using **$THIS_COMMAND @$INSTANCE console**.
		EOF

	log <<< "Starting $INSTANCE_TEXT ..."

	# Load instance configuration
	::hookable App::buildLaunchCommand || return
	LAUNCH_DIR="${LAUNCH_DIR-"$INSTANCE_DIR"}"
	LAUNCH_CMD_REDACTED=$(echo "$LAUNCH_CMD" | sed -E 's/[0-9a-fA-F]{10,}([0-9a-fA-F]{6})/******\1/g')

	info <<< "Server working directory: **$LAUNCH_DIR**"
	info <<< "Server launch command:"
	fmt -w67 <<< "$LAUNCH_CMD_REDACTED" | sed 's/^/        /' | catinfo

	cat > "$TMPDIR/server-start.sh"   <<-EOF
			#! /bin/bash
			$(declare -f timestamp)
			cd "$LAUNCH_DIR"
			script -c '$(quote $LAUNCH_CMD)' "$LOGDIR/\$(timestamp)-server.log"
			echo \$? > "$TMPDIR/server.exit-code"
		EOF

	cat > "$TMPDIR/server-control.sh" <<-EOF
			#! /bin/bash
			APP="$APP"
			THIS_DIR="$THIS_DIR"
			INSTANCE="$INSTANCE"
			MSM_LOGFILE="$LOGDIR/$(timestamp)-controller.log"
			. "\$THIS_DIR/program/server-control.sh" && main
		EOF

	# LAUNCH! (in tmux)

	tmux -f "$THIS_DIR/tmux.conf" -S "$SOCKET" new-session -n "server-control" -s "$APP@$INSTANCE" -d /bin/bash "$INSTANCE_DIR/msm.d/tmp/server-control.sh"

	success <<-EOF
		**$INSTANCE_TEXT** started successfully!

		Use **$THIS_COMMAND @$INSTANCE console** to enter the game's console.
	EOF
}


Core.Server::requestStop () {

	log <<< ""

	if Core.Server::isRunning; then
		out <<< "Stopping $INSTANCE_TEXT ..."

		DEADLINE="$(( $(date +%s) + 30 ))"
		echo "$DEADLINE" > "$TMPDIR/stop"
		# Give 30 seconds to stop 'softly'
		while Core.Server::isRunning && (( $(date +%s) < DEADLINE )); do
			sleep 1
		done

		rm "$TMPDIR/stop"

		# If it hasn't stopped yet, the server will be stopped the hard way now
		kill-tmux

		success <<< "Stopped **$INSTANCE_TEXT**."
	else
		info <<< "$INSTANCE_TEXT is already stopped."
	fi
}


Core.Server::requestRestart () {
	Core.Server::requestStop
	Core.Server::requestStart
}

Core.Server::printStatus () {

	log <<< ""
	requireRunnableInstance || return

	if ! Core.Server::isRunning; then
		info <<< "$INSTANCE_TEXT is STOPPED."
		return
	fi

	if Core.Server::isUpdating; then
		info <<< "$INSTANCE_TEXT is currently UPDATING."
		return
	fi

	info <<< "$INSTANCE_TEXT is RUNNING."
}


# Switch to the game's console running in tmux
Core.Server::attachToConsole () {

	log <<< ""
	requireRunnableInstance || return

	out <<< "Connecting to $INSTANCE_TEXT ..."

	if    Core.Server::isUpdating; then
		tmux -S "$SOCKET" attach
	elif  Core.Server::isRunning;  then
		tmux -S "$SOCKET" attach -t ":$APP-server"
	else
		error <<-EOF
			**$INSTANCE_TEXT** is not running! Start your server using
			**$THIS_COMMAND @$INSTANCE start** and try again.
		EOF
	fi
}


Core.Server::sendCommand () {
	if [[ $@ ]]; then
		log <<< ""
		requireRunnableInstance || return
		Core.Server::isRunning && ! Core.Server::isUpdating || {
			error <<< "**$INSTANCE_TEXT** is not running!"
			return
		}

		local args="$(quote "$@")"
		log <<< "Sending the following command to $INSTANCE_TEXT:"
		log <<< "    $args"

		echo "$args" | tmux-send -t ":$APP-server"
	fi
}
