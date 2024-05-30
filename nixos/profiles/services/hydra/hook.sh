#!@shell@
# shellcheck shell=bash

set -e
set -x

export PATH="@jq@/bin:$PATH"
export PATH="@postgresql@/bin:$PATH"
export PATH="@systemd@/bin:$PATH"
export PATH="@ripgrep@/bin:$PATH"

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
  job=$(jq --raw-output ".job" "$HYDRA_JSON")
  echo "job = $job"

  if [[ $job =~ ^nixos-([^/]*)\.(.*)$ && "$(jq --raw-output '.jobset' "$HYDRA_JSON")" == "main" ]]; then
    host="${BASH_REMATCH[1]}"
    _system="${BASH_REMATCH[2]}"

    build_id=$(jq '.build' "$HYDRA_JSON")
    flake_url=$(psql -t -U hydra -d hydra -c "
          SELECT flake FROM jobsetevals
          WHERE id = (SELECT eval FROM jobsetevalmembers
                      WHERE build = $build_id
                      LIMIT 1)
          ORDER BY id DESC
          LIMIT 1
      ")
    commit=$(echo "$flake_url" | rg --only-matching '/(\w{40})(\?.*)?$' --replace '$1')

    mkdir -p "/tmp/dotfiles-channel-update"
    update_file="/tmp/dotfiles-channel-update/$(basename "$dump_file")"
    jq \
      --arg host "$host" \
      --arg commit "$commit" \
      '{
      host: $host,
      commit: $commit,
      outs: .products | map(.path),
    }' "$HYDRA_JSON" >"$update_file"

    echo "channel update: $update_file"
    cat "$update_file"
    systemctl start "dotfiles-channel-update@$(systemd-escape "$update_file")" --no-block

  else
    echo "job is not a nixos toplevel, or jobset is not main"

    echo "copy out: $out"
    jq --raw-output '.products[].path' "$HYDRA_JSON" | (
      while read -r out; do
        systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service" --no-block
      done
    )
  fi
fi
