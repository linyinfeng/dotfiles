#!@shell@
# shellcheck shell=bash

curl="@curl@/bin/curl"
jq="@jq@/bin/jq"
sponge="@moreutils@/bin/sponge"
systemctl="@systemd@/bin/systemctl"

dir="@directory@"
url="$1"

set -e

set -x

mkdir -p $dir

if [ -f "$dir/config.json" ]; then
  echo 'Backup old config.json'
  cp "$dir/config.json" "$dir/config.json.old"
fi

function cleanup {
  if [ -f "$dir/config.json.old" ]; then
    echo 'Restore old config.json'
    cp "$dir/config.json.old" "$dir/config.json"
    rm "$dir/config.json.old"
  fi
}
trap cleanup EXIT

echo 'Downloading raw config.json...'
raw_config=$(mktemp -t update-sing-box-config.XXXXXXXXXX)
$curl "$url" \
  --fail-with-body \
  --show-error \
  --output "$raw_config"

echo 'Preprocessing raw config.json...'
@preprocessing@

echo 'Build config.json...'
$jq --slurp '.[0] * .[1]' "$raw_config" - <<EOF >"$dir/config.json"
@mixinConfig@
EOF

external_controller_secrets=$(cat "@externalControllerSecretFile@")
$jq "
  .experimental.clash_api.secret = \"${external_controller_secrets}\" |
  .experimental.clash_api.external_ui = \"@webui@\"
" "$dir/config.json" | $sponge "$dir/config.json"

echo 'Remove raw config.json...'
rm "$raw_config"

echo 'Restarting sing-box...'
$systemctl restart sing-box
$systemctl status sing-box --no-pager
if [ -f "$dir/config.json.old" ]; then
  echo 'Remove old config.json'
  rm "$dir/config.json.old"
fi
