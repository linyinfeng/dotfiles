#!@shell@

set -e

source "@common@"
export PATH="@sops@/bin:$PATH"

plain_file="$1"
target_file="$2"
type="$3"
formatter=($4)

message "encryping '$plain_file' to '$target_file' (type: '$type', formatter: '$formatter')..."

if [ -e "$target_file" ]; then
  tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
  target_plain="$tmp_dir/target_plain"
  target_plain_formatted="$tmp_dir/target_plain_formatted"
  plain_formatted="$tmp_dir/plain_formatted"

  function cleanup {
    rm -r "$tmp_dir"
  }
  trap cleanup EXIT

  sops --input-type "$type" --output-type "$type" \
    --decrypt "$target_file" >"$target_plain"

  "${formatter[@]}" "$target_plain" >"$target_plain_formatted"
  "${formatter[@]}" "$plain_file" >"$plain_formatted"

  if diff "$plain_formatted" "$target_plain_formatted" >/dev/null 2>&1; then
    message "same, skipping..."
    exit 0
  fi
fi

EDITOR="cp '$plain_file'" \
  sops --input-type "$type" --output-type "$type" "$target_file"
