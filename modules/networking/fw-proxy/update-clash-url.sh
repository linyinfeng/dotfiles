#!@shell@

mkdir="@coreutils@/bin/mkdir"
mv="@coreutils@/bin/mv"
cp="@coreutils@/bin/cp"
curl="@curl@/bin/curl"
yq="@yqGo@/bin/yq"
systemctl="@systemd@/bin/systemctl"

dir="@directory@"
url="$1"

set -e

$mkdir -p $dir

if [ -f "$dir/config.yaml" ]; then
    echo 'Backup old config.yaml'
    $mv "$dir/config.yaml" "$dir/config.yaml.old"
fi

echo 'Downloading config.yaml...'
tmpfile=$(mktemp /tmp/update-clash-config.XXXXXX)
$curl "$url" > "$tmpfile"

$yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$tmpfile" - <<EOF > "$dir/config.yaml"
@mixinConfig@
EOF

if [ $? -eq 0 ]; then
    echo 'Restarting clash...'
    $systemctl restart clash-premium
    $systemctl status clash-premium
else
    if [ -f "$dir/config.yaml.old" ]; then
        echo 'Restore old config.yaml'
        $cp "$dir/config.yaml.old" "$dir/config.yaml"
    fi
fi
