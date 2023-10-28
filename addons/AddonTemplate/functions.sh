#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# Note: You can register hooks for ::hook calls or functions that are called
# via ::hookable. Prepend before~ or after~ to the hookable function name.
# Remember that hook names are case sensitive.
# Your hooks are passed the hook name and all arguments.

# Tip: Use grep ::hookable -r * to find functions to hook.

# If you miss a hookable function, open an issue or PR at
# https://github.com/dasisdormax/csgo-multiserver

::registerHook before~Core.CommandLine::exec AddonTemplate::info

info <<< "Loading AddonTemplate functions ..."

AddonTemplate::info () {
	echo "$@" | info
}
