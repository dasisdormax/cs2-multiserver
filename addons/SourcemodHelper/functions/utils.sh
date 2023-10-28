#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# downloads a file and validates its checksum
SourcemodHelper::downloadFile () {
	[[ $2 ]] || return
	local cachefile="$SM_FILECACHE_DIR/$2"
	[[ -r $cachefile ]] || {
		local tmp=$(mktemp)
		wget -O "$tmp" "$1" || return
		local sha="$(sha256sum "$tmp")"
		sha=${sha%% *}
		[[ $sha == $2 ]] || {
			error <<< "Mismatched checksum for file $1 (expected $2, got $sha)"
			return 1
		}
		mv "$tmp" "$cachefile"
	}
	echo "$cachefile"
}

SourcemodHelper::unpackZip () {
	local zipfile="$(SourcemodHelper::downloadFile "$@")"
	[[ -r $zipfile ]] && unzip -q "$zipfile"
}

SourcemodHelper::unpackTar () {
	local tarfile="$(SourcemodHelper::downloadFile "$@")"
	[[ -r $tarfile ]] && tar xzf "$tarfile"
}

SourcemodHelper::downloadSmx () {
	local smxname="${3-${1##*/}}"
	local smxfile="$(SourcemodHelper::downloadFile "$@")"
	[[ -r $smxfile ]] && cp "$smxfile" "$SM_TMP_PLUGIN_DIR/$smxname"
}
