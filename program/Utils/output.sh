#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# (C) 2016-2017 Maximilian Wende <dasisdormax@mailbox.org>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




# Debug mode > enable fd 3
if [[ $MSM_DEBUG ]]; then exec 3>&1; else exec 3>/dev/null; fi

# read absolute logfile path
if [[ $MSM_LOGFILE && ! $MSM_LOGFILE =~ ^/ ]]; then
	logdir=$(dirname "$MSM_LOGFILE")
	logdir=$(cd "$logdir" 2>/dev/null && pwd)
	if [[ -w $logdir ]]; then
		MSM_LOGFILE="$logdir/$(basename "$MSM_LOGFILE")"
	else
		MSM_LOGFILE=
	fi
fi




################################### HELPERS ###################################

# Colored output, here for compatibility reasons
caterr  () { printf "\x1b[31m"; cat; printf "\x1b[m"; } >&2

catwarn () { printf "\x1b[33m"; cat; printf "\x1b[m"; } >&2

catinfo () { printf "\x1b[36m"; cat; printf "\x1b[m"; }


# pass output through and, if specified, write to $MSM_LOGFILE
log () {
	if [[ $MSM_LOGFILE ]]; then
		tee -a "$MSM_LOGFILE"
	else
		cat
	fi
}


# indent output by 4 characters
indent () { sed 's/^/    /'; }


# print a 'stack trace'
trace () {
	local i=1
	while [[ ${FUNCNAME[$i]} != main &&
	         ${FUNCNAME[$i]} != Core.CommandLine::exec ]] &&
	      (( i < ${#FUNCNAME[@]} ))
	do
		local func=${FUNCNAME[$i+1]}
		local line=${BASH_LINENO[$i]}
		case $func in
			( command_not_found_handle ) ;;
			( require* ) ;;
			( * )
				if [[ $not_first ]]; then printf "\n             "; fi
				if [[ $func == Core.CommandLine::exec ]]; then
					func="~~ @$INSTANCE ~~ Core.CommandLine::exec"
				fi
				printf "in %-44s (%4s)" "$func" "$line"
				local not_first=1;;
		esac
		(( i++ ))
	done
}


# Make **text framed in double stars** bold
bold () { perl -0777 -pe 's/\*\*(.*?)\*\*/\*\*\x1b[1m$1\x1b[22m\*\*/gs'; }




########################### LOGGING COMMAND WRAPPERS ###########################

log-cmd () {
	[[ $MSM_LOGFILE ]] || {
		$@
		return
	}
	stdbuf -o0 -e0 $@ | tee -a "$MSM_LOGFILE"
}




############################### OUTPUT FUNCTIONS ###############################

fatal () {
	printf "\x1b[35m"

	{	printf "**FATAL:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
	false
} >&2

error () {
	printf "\x1b[31m"

	{	printf "**ERROR:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
	false
} >&2

danger () {
	if [[ ${!1} == 1 ]]; then
		warning
		info <<< "As $1 is set, this script continues anyway ..."
		return
	fi
	(
		cat
		cat <<-EOF

			If you know what you are doing and want to continue anyway,
				export $1=1
			and try again.
		EOF
	) | fatal
}

warning () {
	printf "\x1b[33m"

	printf "**WARNING:** "       | log | bold
	trace                        | log | bold >&3
	{ echo;	fmt -w67 | indent; } | log | bold

	printf "\x1b[m"
}

info () {
	printf "\x1b[36m"

	printf "**INFO:**    "       | log | bold
	trace                        | log | bold >&3
	{ echo;	fmt -w67 | indent; } | log | bold

	printf "\x1b[m"
}

success () {
	printf "\x1b[32m"

	printf "**SUCCESS:** "       | log | bold
	trace                        | log | bold >&3
	{ echo;	fmt -w67 | indent; } | log | bold

	printf "\x1b[m"
}

debug () {
	printf "\x1b[34m"

	{	printf "**DEBUG:**   "; trace; echo
		fmt -w67 | indent;						} | log | bold

	printf "\x1b[m"
} >&3


# Regular output with logging and formatting
out () {
	log | bold
}
