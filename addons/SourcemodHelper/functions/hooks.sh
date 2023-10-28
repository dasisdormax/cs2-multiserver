#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

::registerHook before~App::buildLaunchCommand SourcemodHelper::initVars
::registerHook after~App::buildLaunchCommand SourcemodHelper::updateInstance

SourcemodHelper::updateInstance () {
	[[ $SM_PLUGINS ]] || {
		rmdir "$SM_TMP_DIR" 2>/dev/null
		return
	}
	warning <<-EOF
		The Sourcemod helper plugin is in alpha stage! This will overwrite
		your modifications in your instance's sourcemod file on every launch!
		You can update configuration for all managed instances by modifying
		the files in **$SM_CONFIG_DIR**
	EOF
	(
		cd "$SM_TMP_DIR"
		SourcemodHelper::loadPackage metamod || return
		SourcemodHelper::loadPackage sourcemod || return
		for package in $SM_PACKAGES; do
			SourcemodHelper::loadPackage $package || return
		done
		SourcemodHelper::updateConfig || return
		SourcemodHelper::updatePlugins || return
	) || return

	# Copy addon files to instance's game directory
	cp -r "$SM_TMP_DIR"/* "$SM_TARGET_DIR"

	# Move to last_state directory for easier debugging
	rm -rf "$SM_HOME/last_state"
	mv "$SM_TMP_DIR" "$SM_HOME/last_state"
}

SourcemodHelper::updateConfig () {
	# Initialize config dir
	echo "Updating sourcemod configuration ..."
	mkdir -p "$SM_CONFIG_DIR"
	cp -n "$SM_TMP_CONFIG_DIR/admins_simple.ini" "$SM_CONFIG_DIR"
	cp -n "$SM_TMP_CONFIG_DIR/databases.cfg" "$SM_CONFIG_DIR"
	
	# Copy configs to instance directory
	cp -r "$SM_CONFIG_DIR"/* "$SM_TMP_CONFIG_DIR"
}

SourcemodHelper::updatePlugins () {
	echo "Updating sourcemod plugins ..."

	# Disable all plugins first
	mkdir -p "$SM_TMP_PLUGIN_DIR/disabled"
	mv "$SM_TMP_PLUGIN_DIR"/*.smx "$SM_TMP_PLUGIN_DIR/disabled"

	# Re-enable the plugins that the user wants
	local plugin
	for plugin in $SM_PLUGINS; do
		mv "$SM_TMP_PLUGIN_DIR/disabled/$plugin.smx" "$SM_TMP_PLUGIN_DIR"
	done
}
