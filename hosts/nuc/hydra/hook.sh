#!@shell@

time=$(date --iso-8601=seconds)
jq="@jq@/bin/jq"

mkdir -p /tmp/hydra-hook
output=$(mktemp "/tmp/hydra-hook/$time-XXXXXX")

cp "$HYDRA_JSON" "$output"
