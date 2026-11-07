#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

# downloads a file and validates its checksum
PluginHelper::downloadFile () {
	[[ $2 ]] || return
	local cachefile="$PH_FILECACHE_DIR/$2"
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

PluginHelper::unpackZip () {
	local zipfile="$(PluginHelper::downloadFile "$@")"
	[[ -r $zipfile ]] && unzip -q "$zipfile"
}

PluginHelper::unpackTar () {
	local tarfile="$(PluginHelper::downloadFile "$@")"
	[[ -r $tarfile ]] && tar xzf "$tarfile"
}
