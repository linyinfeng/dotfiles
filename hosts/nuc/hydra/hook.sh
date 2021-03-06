#!@shell@

set -e

jq="@jq@/bin/jq"
psql="@postgresql@/bin/psql"
systemctl="@systemd@/bin/systemctl"

time=$(date --iso-8601=seconds)
mkdir -p "/tmp/hydra-events"
dump_file=$(mktemp "/tmp/hydra-events/$time-XXXXXX.json")
cp "$HYDRA_JSON" "$dump_file"

event=$("$jq" --sort-keys "{project, jobset, nixName, buildStatus}" "$HYDRA_JSON")
echo "event = $event"

# channel update event
expected=$("$jq" --sort-keys . <<EOF
{
    "project": "dotfiles",
    "jobset": "main",
    "nixName": "all-checks",
    "buildStatus": 0
}
EOF
)
echo "expected = $expected"
if [ "$event" = "$expected" ]; then
    build_id=$("$jq" '.build' "$HYDRA_JSON")
    flake_url=$("$psql" -t -U hydra -d hydra -c "
        SELECT flake FROM jobsetevals
        WHERE id = (SELECT eval FROM jobsetevalmembers
                    WHERE build = $build_id)
        ORDER BY id DESC
        LIMIT 1
    ")
    commit=$(echo "$flake_url" | grep -E -o '\w{40}$')
    echo "channel update: $commit"
    "$systemctl" start "dotfiles-channel-update@$commit" --no-block
fi
