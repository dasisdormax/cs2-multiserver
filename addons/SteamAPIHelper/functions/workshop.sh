#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SteamAPIHelper::loadWorkshop () {
	[[ $WORKSHOP_COLLECTION_ID ]] || return 0
	SteamAPIHelper::requireKey || return

	local URL
	local DATA
	local ID
	local MAPNAME
	local MAP_TRIPLE
	local WORKSHOP_SUBSCRIBED="$CSGO_DIR/subscribed_file_ids.txt"
	local WORKSHOP_RESULT="$CSGO_DIR/.workshop_result.txt"

	# Load info about collection
	echo "Loading collection $WORKSHOP_COLLECTION_ID from Workshop ..."
	URL=https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/
	DATA="collectioncount=1&publishedfileids[0]=$WORKSHOP_COLLECTION_ID"
	wget -q --post-data "$DATA" "$URL" -O "$WORKSHOP_RESULT" || {
		error <<< "Collection not found! Make sure the ID is correct and the collection is not private!"
		exit
	}
	# Parse JSON and load file details for each item in the collection
	MAPGROUP=mg_workshop
	cat > "$GAMEMODES_TXT" <<-EOF 
		"mapgroups" { "mg_workshop" {
		"name" "mg_workshop"
		"maps" {
	EOF
	MAPS=()
	rm -f "$WORKSHOP_SUBSCRIBED"
	URL=https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/
	for ID in $(cat "$WORKSHOP_RESULT" | jq -r .response.collectiondetails[].children[].publishedfileid); do
		DATA="itemcount=1&publishedfileids[0]=$ID&key=$APIKEY"
		wget -q --post-data "$DATA" "$URL" -O "$WORKSHOP_RESULT" || continue
		MAPNAME="$(cat "$WORKSHOP_RESULT" | jq -r .response.publishedfiledetails[].title)"
		MAPNAME=${MAPNAME,,}
		[[ $MAPNAME ]] || continue
		MAP_TRIPLE="workshop/$ID/$MAPNAME"
		MAPS+=( "$MAP_TRIPLE" )
		echo "Adding map $MAP_TRIPLE ..."
		echo "$ID" >> "$WORKSHOP_SUBSCRIBED"
		echo "\"$MAP_TRIPLE\" \"\"" > "$GAMEMODES_TXT"
	done
	echo '}}}' > "$GAMEMODES_TXT"
}