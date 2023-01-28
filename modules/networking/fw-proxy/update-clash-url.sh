#!@shell@

curl="@curl@/bin/curl"
yq="@yqGo@/bin/yq"
systemctl="@systemd@/bin/systemctl"

dir="@directory@"
url="$1"

set -e

mkdir -p $dir

if [ -f "$dir/config.yaml" ]; then
    echo 'Backup old config.yaml'
    cp "$dir/config.yaml" "$dir/config.yaml.old"
fi

function cleanup {
    if [ -f "$dir/config.yaml.old" ]; then
        echo 'Restore old config.yaml'
        cp "$dir/config.yaml.old" "$dir/config.yaml"
        rm "$dir/config.yaml.old"
    fi
}
trap cleanup EXIT

echo 'Downloading raw config.yaml...'
tmpfile=$(mktemp /tmp/update-clash-config.XXXXXX)
$curl "$url" \
  --fail-with-body \
  --show-error \
  --output "$tmpfile"

echo 'Build config.yaml...'
$yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$tmpfile" - <<EOF > "$dir/config.yaml"
@mixinConfig@
EOF

echo 'Remove raw config.yaml...'
rm "$tmpfile"

echo 'Restarting clash...'
$systemctl restart clash
$systemctl status clash
if [ -f "$dir/config.yaml.old" ]; then
    echo 'Remove old config.yaml'
    rm "$dir/config.yaml.old"
fi
