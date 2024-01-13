#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0





::init () {
	RequestedModules=
	Modules=
}

# Add a module to the list of requested modules
# Automatically takes care of duplicates
::add () {
	list-contains "$RequestedModules" $1 || RequestedModules="$RequestedModules $1"
}

# Remove a module from the list of requested modules
::remove () {
	RequestedModules=$(list-diff "$RequestedModules" $1)
}

::update () {
	::unloadModules $(list-diff "$Modules" "$RequestedModules")
	::loadModules   $(list-diff "$RequestedModules" "$Modules")
}

# unloads all modules if any is set to be removed
#
# Unloads all modules because remaining modules may still expect the
# others to be available
#
# Things *may* get weird when unloading Core modules whose functions are
# still 'on the stack' and active. Only testing will find out.
::unloadModules () {
	if [[ ! $@ ]]; then return 0; fi

	local module
	local funs

	# first: execute all unload handlers
	for module in $Modules; do
		::execHandler $module unload; done

	# second: delete all module functions
	# NOTE: only namespaced functions are deleted. If your module uses,
	#       non-namespaced ones, unset them in your unload handler
	for module in $Modules; do
		unset -f $(::moduleFuns $module); done

	Modules=
}

# Loads the given modules' functions, applies before and after function
# modifications and triggers their load event
::loadModules () {
	local module
	local errno

	# first: load module functions
	for module in $*; do
		# No Namespace filtering, you have to trust the module anyway to not mess stuff up
		::execHandler $module functions && Modules="$module $Modules" || errno=1; done

	# second: execute load handler
	for module in $*; do
		::execHandler $module load; done

	return $errno
}

::moduleDir () {
	local dir=${1//./\/}
	# first:  msm's program -> core modules
	# second: msm's bundled addons
	# third:  the user's own addons
	local candidates=( "$THIS_DIR/program/$dir" "$THIS_DIR/addons/$dir" "$USER_DIR/addons/$dir" )
	for dir in ${candidates[@]}; do
		[[ -d $dir ]] && echo $dir && return 0; done
	return 1
}

::moduleFuns () {
	declare -f -F | grep -o "\<$1::.*$"
}

::execHandler () {
	local dir="$(::moduleDir $1)" && . "$dir/$2"
}

###### Hook system for addons ######
ALL_HOOKS=" "

::hookable () {
	[[ $1 ]] && ::hook "before~$@" && ::innerHook "$@" && ::hook "after~$@"
}

# Executes the functions registered to the given hook.
#
# Multiple functions may be registered to a single hook. They will be executed in the
# order they were registered. If a function is not found or returns false, this function
# will stop executing and return false too
# The hook is passed the hook name and all extra arguments given
::hook () {
	local line
	for line in $ALL_HOOKS; do
		[[ $line =~ ^$1@ ]] || continue
		${line#$1@} "$@" || return
	done
	return 0
}

::innerHook () {
	if declare -f -F "$1" >/dev/null; then
		"$@"
		return
	fi
	::hook "$@"
}

# Registers a function ($2) to a named hook ($1)
::registerHook () {
	local newhook="$1@$2"
	ALL_HOOKS="${ALL_HOOKS//$newhook }$newhook "
}



::loadAddons () {
	local addon
	for addon in $MSM_ADDONS; do
		::add $addon
	done
	::update
}

::loadApp () {
	local dir
	# The global app directory has priority over the user's
	local candidates=( "$THIS_DIR/$APP/app" "$USER_DIR/$APP/app" )
	for dir in ${candidates[@]}; do
		if [[ -r $dir/app.info ]]; then
			# Set app-specific variables
			APP_DIR="$dir"
			CFG_DIR="$USER_DIR/$APP/cfg"
			CFG="$CFG_DIR/defaults.conf"

			# Load the app itself
			.file "$dir/app.info" && . "$dir/functions"
			return
		fi
	done
	return 1
}

export IFS=$' \t\r\n'

# override command not found message
command_not_found_handle () {
	if [[ $1 =~ $'\r' ]]; then
		local file="${BASH_SOURCE[1]}"
		catwarn <<< "Warning: File '$file' contains windows line endings and might be processed incorrectly."
		return
	fi
	error <<< "**$1** - command not found"
	local mod=$(echo $1 | grep -o '^..*::')
	if [[ $mod ]]; then
		out <<< ""
		local mod=${mod::-2}
		local funs=$(::moduleFuns $mod)

		if [[ $funs ]]; then
			out <<< "    Functions currently defined in the **$mod** namespace:" | caterr
			local fun
			for fun in $funs; do
				out <<< "        $fun" | caterr
			done
		else
			out <<-EOF | caterr
				    The module **$mod** is not loaded
				    or does not provide any functions.
			EOF
		fi
	fi

	return 127
}
