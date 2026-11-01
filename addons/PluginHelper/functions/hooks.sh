#! /bin/bash

::registerHook before~App::buildLaunchCommand PluginHelper::initVars
::registerHook after~App::buildLaunchCommand PluginHelper::updateInstance

PluginHelper::updateInstance () (
	trap 'rm -rf -- "$SM_TMP_DIR"' EXIT
	cd "$SM_TMP_DIR" || return
	PluginHelper::loadPackage metamod || return
	PluginHelper::loadPackage counterstrikesharp || return

	local gameinfo="$SM_TARGET_DIR/gameinfo.gi"
	[[ -f $gameinfo && ! -L $gameinfo ]] || {
		error <<< "Cannot update instance gameinfo.gi: $gameinfo"
		return 1
	}
	if ! grep -Eq '^[[:space:]]*Game[[:space:]]+csgo/addons/metamod([[:space:]]|$)' "$gameinfo"; then
		grep -Eq '^[[:space:]]*Game_LowViolence[[:space:]]+csgo_lv' "$gameinfo" || {
			error <<< "Cannot find the Metamod insertion point in $gameinfo."
			return 1
		}
		local tmpfile
		tmpfile=$(mktemp "${gameinfo}.XXXXXX") || return
		sed '/^[[:space:]]*Game_LowViolence[[:space:]]\+csgo_lv/a\			Game csgo/addons/metamod' "$gameinfo" > "$tmpfile" || { rm -f "$tmpfile"; return 1; }
		chmod --reference="$gameinfo" "$tmpfile" && mv -f "$tmpfile" "$gameinfo" || return
	fi

	# Package defaults must not replace user plugins or configuration.
	local dir
	for dir in configs plugins; do
		if [[ -d "addons/counterstrikesharp/$dir" ]]; then
			mkdir -p "$SM_TARGET_DIR/addons/counterstrikesharp/$dir" || return
			cp -rn "addons/counterstrikesharp/$dir/." "$SM_TARGET_DIR/addons/counterstrikesharp/$dir/" || return
			rm -rf "addons/counterstrikesharp/$dir" || return
		fi
	done
	if [[ -e "$SM_TARGET_DIR/addons/metamod/metaplugins.ini" ]]; then
		rm -f addons/metamod/metaplugins.ini || return
	fi
	cp -r addons "$SM_TARGET_DIR/" || return
)
