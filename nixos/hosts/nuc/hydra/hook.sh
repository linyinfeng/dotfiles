#!@shell@

set -e

jq="@jq@/bin/jq"
psql="@postgresql@/bin/psql"
systemctl="@systemd@/bin/systemctl"

time=$(date --iso-8601=seconds)
mkdir -p "/tmp/hydra-events"
dump_file=$(mktemp "/tmp/hydra-events/$time-XXXXXX.json")
cp "$HYDRA_JSON" "$dump_file"

event=$("$jq" --sort-keys "{project, jobset, buildStatus, event}" "$HYDRA_JSON")
echo "event = $event"

expected=$(
  "$jq" --sort-keys . <<EOF
{
  "project": "dotfiles",
  "jobset": "main",
  "buildStatus": 0,
  "event": "buildFinished"
}
EOF
)
echo "expected = $expected"

if [ "$event" = "$expected" ]; then
  job=$("$jq" -r ".job" "$HYDRA_JSON")

  if [[ $job =~ ^(.*)\.nixos/(.*)$ ]]; then
    system="${BASH_REMATCH[1]}"
    host="${BASH_REMATCH[2]}"

    build_id=$("$jq" '.build' "$HYDRA_JSON")
    flake_url=$("$psql" -t -U hydra -d hydra -c "
          SELECT flake FROM jobsetevals
          WHERE id = (SELECT eval FROM jobsetevalmembers
                      WHERE build = $build_id)
          ORDER BY id DESC
          LIMIT 1
      ")
    commit=$(echo "$flake_url" | grep -E -o '\w{40}$')

    out=$("$jq" -r '.outputs[0].path' "$HYDRA_JSON")

    mkdir -p "/tmp/dotfiles-channel-update"
    update_file="/tmp/dotfiles-channel-update/$(basename "$dump_file")"
    cat >"$update_file" <<EOF
{
  "host": "$host",
  "commit": "$commit",
  "out": "$out"
}
EOF
    $update_file_name=$(basename "$update_file")
    echo "channel update: $update_file_name"
    cat "$update_file"
    "$systemctl" start "dotfiles-channel-update@$(systemd-escape "$update_file")" --no-block

  fi
fi
