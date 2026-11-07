#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# Exercise real controller transitions and PluginHelper hooks without Steam or tmux.
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT

run_case () (
	case_name=$1
	INSTANCE=$2
	plugin_enabled=$3
	failure=$4
	case_dir="$fixture/$case_name"
	THIS_DIR=$repo
	APP=cs2
	builtin . "$repo/program/server-control.sh"
	USER_DIR="$case_dir/user"
	base="$case_dir/base"
	target=$base
	suffix=base
	if [[ $INSTANCE ]]; then
		suffix="inst-$INSTANCE"
		target="$USER_DIR/cs2/$suffix"
	fi
	mkdir -p "$base/msm.d" "$target/msm.d/tmp" "$target/game/csgo" \
		"$USER_DIR/cs2/cfg/$suffix" "$USER_DIR/cs2/log/$suffix" \
		"$USER_DIR/addons/PreparationProbe"
	echo cs2 > "$base/msm.d/app"
	echo cs2 > "$target/msm.d/app"
	touch "$base/msm.d/is-admin"
	touch -d '2000-01-01' "$target/msm.d/app"
	if [[ $INSTANCE ]]; then
		touch -d '2020-01-01' "$base/msm.d/app"
	fi
	cat > "$target/game/csgo/gameinfo.gi" <<-'EOF'
		Game_LowViolence csgo_lv
	EOF
	cat > "$target/msm.d/tmp/server-start.sh" <<-'EOF'
		# The controller must keep the saved launch command.
		exit 0
	EOF
	launch_script=$(cat "$target/msm.d/tmp/server-start.sh")
	cat > "$USER_DIR/cs2/cfg/defaults.conf" <<-EOF
		ADMIN=test
		INSTALL_DIR="$base"
		MSM_ADDONS="${plugin_enabled:+PluginHelper }SteamAPIHelper PreparationProbe"
	EOF

	# This addon replaces external operations, but keeps the real addon loader,
	# hook engine, PluginHelper preparation and controller state machine.
	cat > "$USER_DIR/addons/PreparationProbe/functions.sh" <<-'EOF'
		PluginHelper::loadPackage () {
			event "package $1"
			[[ $failure != preparation ]] || return 17
			mkdir -p addons/metamod addons/counterstrikesharp
		}
		SteamAPIHelper::handleGSLT () {
			event unexpected-token-change
			return 1
		}
		Core.Instance::symlinkFiles () {
			event synchronize
			[[ $failure != synchronization ]]
		}
		App::finalizeInstance () { event finalize; }
		App::applyInstancePermissions () { event permissions; }
		Core.Wrapper::stopServerForUpdate () {
			event update
			# Simulate an update replacing gameinfo.gi before the next launch.
			cat > "$INSTANCE_DIR/game/csgo/gameinfo.gi" <<-'GAMEINFO'
				Game_LowViolence csgo_lv
			GAMEINFO
			touch "$INSTALL_DIR/msm.d/app"
			rm "$INSTALL_DIR/msm.d/update"
		}
	EOF

	event () { echo "$*" >> "$case_dir/events"; }
	launches=0
	tmux () {
		[[ $1 == new-window ]] || return 1
		event launch
		[[ $failure != launch ]] || return 19
		if [[ $plugin_enabled ]]; then
			[[ $(grep -c 'Game csgo/addons/metamod' "$target/game/csgo/gameinfo.gi") == 1 ]] || return 20
		else
			! grep -q metamod "$target/game/csgo/gameinfo.gi" || return 21
		fi
		launches=$((launches + 1))
		case $launches in
			1) date +%s > "$INSTALL_DIR/msm.d/update" ;;
			2) echo 7 > "$TMPDIR/server.exit-code" ;;
			3) echo 0 > "$TMPDIR/server.exit-code" ;;
			*) return 22 ;;
		esac
	}
	# A healthy test completes every transition without waiting for real events.
	inotifywait () { event unexpected-wait; exit 1; }
	status=0
	main > "$case_dir/controller.log" 2>&1 || status=$?
	if [[ $failure ]]; then
		[[ $status == 1 && $launches == 0 ]]
		grep -q 'Server launch failed' "$case_dir/controller.log"
		if [[ $failure != launch ]]; then
			! grep -qx launch "$case_dir/events"
		fi
	else
		[[ $status == 0 && $launches == 3 ]]
		grep -q 'Relaunching server due to a crash' "$case_dir/controller.log"
		if [[ $plugin_enabled ]]; then
			[[ $(grep -c '^package ' "$case_dir/events") == 6 ]]
			if [[ $INSTANCE ]]; then
				# Both synchronizations must finish before plugin preparation.
				expected=$(cat <<-'EOF'
					synchronize
					finalize
					permissions
					package metamod
					package cssharp
					launch
					update
					synchronize
					finalize
					permissions
					package metamod
					package cssharp
					launch
					package metamod
					package cssharp
					launch
				EOF
				)
				[[ $(cat "$case_dir/events") == "$expected" ]] || {
					cat "$case_dir/events" >&2
					exit 1
				}
			fi
		else
			! grep -q '^package ' "$case_dir/events"
		fi
	fi
	! grep -Eq 'unexpected-|command not found' "$case_dir/events" "$case_dir/controller.log"
	[[ $(cat "$target/msm.d/tmp/server-start.sh") == "$launch_script" ]]
	if [[ $plugin_enabled && $failure != synchronization ]]; then
		[[ -z $(find "$USER_DIR/cs2/addons/plugin-helper/tmp" -mindepth 1 -print -quit) ]]
	fi
	echo "PASS: $case_name"
)

run_case base '' yes ''
run_case instance test01 yes ''
run_case disabled test01 '' ''
run_case preparation-failure '' yes preparation
run_case synchronization-failure test01 yes synchronization
run_case launch-failure '' yes launch
