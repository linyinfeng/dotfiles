{
  config,
  pkgs,
  lib,
  ...
}:
let
  hydraHook = pkgs.writeShellApplication {
    name = "hydra-hook";
    runtimeInputs = with pkgs; [
      jq
      systemd
      getFlakeCommit
      channelUpdate
    ];
    text = ''
      echo "--- begin event ---"
      cat "$HYDRA_JSON" | jq
      echo "--- end event ---"

      if [ "$(jq '.event == "buildFinished" and .buildStatus == 0' "$HYDRA_JSON")"  != "true" ]; then
        echo "not a successful buildFinished event, exit."
        exit 0
      fi

      echo "copying outputs to cache..."
      jq --raw-output '.outputs[].path' "$HYDRA_JSON" | while read -r out; do
        echo "copying to cache: $out..."
        systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service"
        echo "done."
      done

      if [ "$(jq --from-file "${dotfilesChannelJobFilter}" "$HYDRA_JSON")" = "true" ]; then
        echo "dotfiles channel job detected, update channel..."
        host="$(jq --raw-output '.job | capture("^nixos-(?<host>[^/]*)\\.(.*)$").host' "$HYDRA_JSON")"
        branch="nixos-tested-$host"
        commit="$(get-flake-commit)"
        channel-update "linyinfeng" "dotfiles" "$branch" "$commit"
      fi
    '';
  };
  dotfilesChannelJobFilter = pkgs.writeTextFile {
    name = "nixos-job-filter.jq";
    text = ''
      .project == "dotfiles" and
      .jobset == "main" and
      (.job | test("^nixos-([^/]*)\\.(.*)$"))
    '';
  };
  # currently github only
  channelUpdate = pkgs.writeShellApplication {
    name = "channel-update";
    runtimeInputs = with pkgs; [
      jq
      git
      util-linux
    ];
    text = ''
      owner="$1"
      repo="$2"
      branch="$3"
      commit="$4"
      token=$(cat "$CREDENTIALS_DIRECTORY/github-token")

      echo "updating $owner/$repo/$branch to $commit..."

      cd /var/tmp
      mkdir --parents "hydra-channel-update/$owner/$repo"
      cd "hydra-channel-update/$owner/$repo"

      (
        echo "waiting for repository lock..."
        flock 200
        echo "enter critical section"

        if [ ! -d "repo.git" ]; then
          git clone "https://github.com/$owner/$repo.git" --filter=tree:0 --bare repo.git
        fi

        function repo-git {
          git -C repo.git "$@"
        }

        repo-git remote set-url origin "https://-:$token@github.com/$owner/$repo.git"
        repo-git fetch --all
        if repo-git merge-base --is-ancestor "$commit" "$branch"; then
          echo "commit $commit is already in branch $branch, skip."
          exit 0
        fi
        repo-git push origin "$commit:$branch"

        echo "leave critical section"
      ) 200>lock
    '';
  };
  getFlakeCommit = pkgs.writeShellApplication {
    name = "get-flake-commit";
    runtimeInputs = with pkgs; [
      jq
      postgresql
      ripgrep
    ];
    text = ''
      build_id=$(jq '.build' "$HYDRA_JSON")
      flake_url=$(psql --tuples-only --username=hydra --dbname=hydra --command="
          SELECT flake FROM jobsetevals
          WHERE id = (SELECT eval FROM jobsetevalmembers
                      WHERE build = $build_id
                      LIMIT 1)
          ORDER BY id DESC
          LIMIT 1
        ")
      echo "$flake_url" | rg --only-matching '/(\w{40})(\?.*)?$' --replace '$1'
    '';
  };
in
{
  services.hydra.extraConfig = lib.mkAfter ''
    <runcommand>
      command = "${lib.getExe hydraHook}"
    </runcommand>
  '';
  systemd.services.hydra-notify.serviceConfig.LoadCredential = [
    "github-token:${config.sops.secrets."github_token_nano".path}"
  ];
  sops.secrets."github_token_nano".restartUnits = [ "hydra-notify.service" ];
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          RegExp('copy-cache-li7g-com@.+\.service').test(action.lookup("unit")) === true &&
          subject.isInGroup("hydra")) {
        return polkit.Result.YES;
      }
    });
  '';
}
