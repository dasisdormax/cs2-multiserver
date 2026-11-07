#!/bin/bash
set -eu
cd "$(dirname "$0")/.."
. addons/SteamAPIHelper/functions/token.sh

testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
SAH_TOKEN_FILE="$testdir/token"
APIKEY=key
SAH_APPID=730
INSTANCE=test
query_response='{"response":{"steamid":"76561198000000001"}}'
reset_response='{"response":{"login_token":"reset-token"}}'
create_response='{"response":{"steamid":"76561198000000002","login_token":"new-token"}}'
query_status=0
reset_status=0
create_status=0

wget() {
	local url output
	if [[ $2 == --post-data ]]; then url=$4; output=$6; else url=$2; output=$4; fi
	case "$url" in
		*QueryLoginToken*) printf '%s\n' "$query_response" > "$output"; return "$query_status" ;;
		*ResetLoginToken*) printf '%s\n' "$reset_response" > "$output"; return "$reset_status" ;;
		*CreateAccount*) printf '%s\n' "$create_response" > "$output"; return "$create_status" ;;
		*) echo "Unexpected request" >&2; return 1 ;;
	esac
}

assert_file() {
	local expected
	expected=$(cat <<-EOF
		$1
		$2
	EOF
	)
	[[ $(cat "$SAH_TOKEN_FILE") == "$expected" ]]
}
old_id=76561198000000001
new_id=76561198000000002
cat > "$SAH_TOKEN_FILE" <<-EOF
	old-token
	$old_id
EOF
SteamAPIHelper::checkExistingToken
[[ $GSLT == reset-token ]]
assert_file reset-token "$old_id"

reset_response='{"response":{}}'
SteamAPIHelper::checkExistingToken
[[ $GSLT == new-token ]]
assert_file new-token "$new_id"

cat > "$SAH_TOKEN_FILE" <<-EOF
	old-token
	$old_id
EOF
reset_status=8
SteamAPIHelper::checkExistingToken
[[ $GSLT == old-token ]]
assert_file old-token "$old_id"
reset_status=0
for reset_response in '{}' '{"response":{"error":"unavailable"}}' 'invalid'; do
	SteamAPIHelper::checkExistingToken
	[[ $GSLT == old-token ]]
	assert_file old-token "$old_id"
done
reset_response='{"response":{}}'
create_status=8
SteamAPIHelper::checkExistingToken
[[ $GSLT == old-token ]]
assert_file old-token "$old_id"
create_status=0
create_response='{"response":{}}'
SteamAPIHelper::checkExistingToken
[[ $GSLT == old-token ]]
assert_file old-token "$old_id"

printf 'old-token\n' > "$SAH_TOKEN_FILE"
reset_response='{"response":{"login_token":"reset-token"}}'
SteamAPIHelper::checkExistingToken
[[ $GSLT == reset-token ]]
assert_file reset-token "$old_id"
printf 'old-token\n' > "$SAH_TOKEN_FILE"
query_status=8
SteamAPIHelper::checkExistingToken
[[ $GSLT == old-token && $(cat "$SAH_TOKEN_FILE") == old-token ]]

rm "$SAH_TOKEN_FILE"
create_response='{"response":{"steamid":"76561198000000002","login_token":"new-token"}}'
SteamAPIHelper::getNewToken
[[ $GSLT == new-token ]]
assert_file new-token "$new_id"
