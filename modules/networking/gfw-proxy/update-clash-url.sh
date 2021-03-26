#!@shell@

mkdir="@coreutils@/bin/mkdir"
mv="@coreutils@/bin/mv"
chown="@coreutils@/bin/chown"
cp="@coreutils@/bin/cp"
curl="@curl@/bin/curl"
yq="@yqGo@/bin/yq"
systemctl="@systemd@/bin/systemctl"

http_port="@httpPort@"
socks_port="@socksPort@"
mixed_port="@mixedPort@"
external_controller_port="@externalControllerPort@"

dir="@directory@"
url="$1"

set -e

$mkdir -p $dir

if [ -f "$dir/config.yaml" ]; then
    echo 'Backup old config.yaml'
    $mv "$dir/config.yaml" "$dir/config.yaml.old"
fi

export HTTP_PROXY=
export HTTPS_PROXY=
export ALL_PROXY=
export http_proxy=
export https_proxy=
export all_proxy=

echo 'Downloading config.yaml...'
tmpfile=$(mktemp /tmp/update-clash-config.XXXXXX)
$curl "$url" > "$tmpfile"

$yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$tmpfile" - <<EOF > "$dir/config.yaml"
port: $http_port
socks-port: $socks_port
mixed-port: $mixed_port
external-controller: 127.0.0.1:$external_controller_port
EOF

$chown clash "$dir/config.yaml"

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
