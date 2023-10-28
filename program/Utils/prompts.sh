#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# A yes/no prompt. With the first parameter $1, an alternative prompt message can be given.
# returns true (0) for yes, and false (1) for no. Defaults to YES
promptY () {
	local PROMPT=${1-"Proceed?"}
	if [[ $1 ]]; then local PROMPT="$1"; fi

	echo
	read -r -p "$PROMPT ($(printf "\x1b[1mY\x1b[22m")/n) " INPUT

	# Implicit return value below
	[[ ! $INPUT || $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}

# A similar prompt that defaults to NO instead
promptN () {
	local PROMPT=${1-"Are you sure?"}

	# Prompt (in yellow, as warning color)
	printf "\n\x1b[33m"
	read -r -p "$PROMPT (y/$(printf "\x1b[1mN\x1b[22m")) " INPUT
	printf "\x1b[m"

	# Implicit return value below
	[[ $INPUT =~ ^([Yy]|[Yy][Ee][Ss])$ ]]
}
