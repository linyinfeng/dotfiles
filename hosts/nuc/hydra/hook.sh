#!@shell@

time=$(date --iso-8601=seconds)
mkdir -p /tmp/hydra-hook
output=$(mktemp "/tmp/hydra-hook/$time-XXXXXX")
cat > "$output" <<EOF
$HYDRA_JSON
EOF
