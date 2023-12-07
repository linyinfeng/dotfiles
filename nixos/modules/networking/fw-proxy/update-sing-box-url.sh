#!@shell@
# shellcheck shell=bash

curl="@curl@/bin/curl"
jq="@jq@/bin/jq"
yq="@yq@/bin/yq"
sponge="@moreutils@/bin/sponge"
systemctl="@systemd@/bin/systemctl"
ctos="@clash2SingBox@"

dir="@directory@"

set -e

url=""
downloaded_config_type="sing-box"
keep_temporary_directory="NO"
profile_name=""

positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  --clash)
    downloaded_config_type="clash"
    shift
    ;;
  --keep-temporary-directory)
    keep_temporary_directory="YES"
    shift
    ;;
  --profile-name)
    profile_name="$2"
    shift
    shift
    ;;
  -* | --*)
    echo "unknown option $1" >&2
    exit 1
    ;;
  *)
    positional_args+=("$1")
    shift
    ;;
  esac
done
if [ "${#positional_args[@]}" = "1" ]; then
  url="${positional_args[0]}"
else
  echo "invalid arguments ${positional_args[@]}" >&2
  exit 1
fi

mkdir -p $dir

echo 'Making temporary directory...'
tmp_dir=$(mktemp -t --directory update-sing-box-config.XXXXXXXXXX)
echo "Temporary directory is: $tmp_dir"
if [ -f "$dir/config.json" ]; then
  echo 'Backup old config.json...'
  cp "$dir/config.json" "$dir/config.json.old"
fi
function cleanup {
  if [ "$keep_temporary_directory" != "YES" ]; then
    echo 'Remove temporary directory...'
    rm -rf "$tmp_dir"
  fi
  if [ -f "$dir/config.json.old" ]; then
    echo 'Restore old config.json...'
    cp "$dir/config.json.old" "$dir/config.json"
    rm "$dir/config.json.old"
  fi
}
trap cleanup EXIT

echo 'Downloading original configuration...'
downloaded_config="$tmp_dir/downloaded-config"
$curl "$url" \
  --fail-with-body \
  --show-error \
  --output "$downloaded_config"
profile_info_file="$tmp_dir/profile-info"
$jq --null-input \
    --arg url "$url" \
    --arg profile_name "$profile_name" \
    '{"url": $url, "profile_name": $profile_name}' \
    >"$profile_info_file"

echo 'Preprocessing original configuration...'
@preprocessingDownloaded@

echo 'Converting downloaded configuration file to raw config.json...'
raw_config="$tmp_dir/raw-config.json"
if [ "$downloaded_config_type" = "sing-box" ]; then
  cp "$downloaded_config" "$raw_config"
elif [ "$downloaded_config_type" = "clash" ]; then
  $ctos --source="$downloaded_config" gen >"$raw_config"
else
  echo "unknown config type: ${downloaded_config_type}" >&2
  exit 1
fi

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

echo 'Restarting sing-box...'
$systemctl restart sing-box
$systemctl status sing-box --no-pager
if [ -f "$dir/config.json.old" ]; then
  echo 'Remove old config.json...'
  rm "$dir/config.json.old"
fi
