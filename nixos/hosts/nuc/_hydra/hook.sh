#!@shell@
# shellcheck shell=bash

set -e

export PATH="@jq@/bin:$PATH"
export PATH="@postgresql@/bin:$PATH"
export PATH="@systemd@/bin:$PATH"

time=$(date --iso-8601=seconds)
mkdir -p "/tmp/hydra-events"
dump_file=$(mktemp "/tmp/hydra-events/$time-XXXXXX.json")
cp "$HYDRA_JSON" "$dump_file"

hit=$(jq '
  .project == "dotfiles" and
  (.jobset == "main" or .jobset == "staging") and
  .buildStatus == 0 and
  .event == "buildFinished"
' "$HYDRA_JSON")
echo "hit = $hit"

if [ "$hit" = "true" ]; then
  job=$(jq -r ".job" "$HYDRA_JSON")
  echo "job = $job"

  if [[ $job =~ ^(.*)\.nixos/(.*)$ && "$(jq --raw-output '.jobset' "$HYDRA_JSON")" == "main" ]]; then
    _system="${BASH_REMATCH[1]}"
    host="${BASH_REMATCH[2]}"

    build_id=$(jq '.build' "$HYDRA_JSON")
    flake_url=$(psql -t -U hydra -d hydra -c "
          SELECT flake FROM jobsetevals
          WHERE id = (SELECT eval FROM jobsetevalmembers
                      WHERE build = $build_id
                      LIMIT 1)
          ORDER BY id DESC
          LIMIT 1
      ")
    commit=$(echo "$flake_url" | grep -E -o '\w{40}$')

    out=$(jq -r '.outputs[0].path' "$HYDRA_JSON")

    mkdir -p "/tmp/dotfiles-channel-update"
    update_file="/tmp/dotfiles-channel-update/$(basename "$dump_file")"
    cat >"$update_file" <<EOF
{
  "host": "$host",
  "commit": "$commit",
  "out": "$out"
}
EOF
    echo "channel update: $update_file"
    cat "$update_file"
    systemctl start "dotfiles-channel-update@$(systemd-escape "$update_file")" --no-block

  else
    echo "job is not a nixos toplevel, or jobset is not main"

    echo "copy out: $out"
    out=$(jq -r '.outputs[0].path' "$HYDRA_JSON")
    systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service" --no-block
  fi
fi
