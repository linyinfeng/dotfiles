{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services."dotfiles-channel-update@" = {
    script = ''
      cd "$STATE_DIRECTORY"

      update_file="$1"
      echo "update_file = $update_file"

      host=$(jq --raw-output '.host' "$update_file")
      echo "host = $host"
      commit=$(jq --raw-output '.commit' "$update_file")
      echo "commit = $commit"

      target_branch="nixos-tested-$host"
      echo "target_branch = $target_branch"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        jq --raw-output '.outs[]' "$update_file" | (
          while read -r out; do
            echo "copy to cache: $out"
            systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service"
          done
        )

        # update channel
        if [ ! -d dotfiles ]; then
          git clone https://github.com/linyinfeng/dotfiles.git
          pushd dotfiles
          token=$(cat "$CREDENTIALS_DIRECTORY/github-token")
          git remote set-url origin "https://littlenano:$token@github.com/linyinfeng/dotfiles.git"
          popd
        fi
        cd dotfiles
        git fetch origin --verbose
        if git show-ref --quiet refs/heads/"$target_branch"; then
          git checkout "$target_branch"
        else
          git checkout -b "$target_branch"
        fi
        git reset --hard "$commit"
        git push origin "$target_branch" --force --verbose

        set +e
        ${config.programs.tg-send.wrapped} <<EOF
      dotfiles/$target_branch

      $(git show HEAD --no-patch)
      EOF
        set -e
      ) 200>/var/lib/dotfiles-channel-update/lock
    '';
    scriptArgs = "%I";
    path = with pkgs; [
      git
      jq
      config.nix.package
      util-linux
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      SupplementaryGroups = [ config.users.groups.tg-send.name ];
      StateDirectory = "dotfiles-channel-update";
      Restart = "on-failure";
      LoadCredential = [ "github-token:${config.sops.secrets."github_token_nano".path}" ];
    };
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  };
  sops.secrets."github_token_nano" = {
    predefined.enable = true;
    restartUnits = [ "dotfiles-channel-update@.service" ];
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          RegExp('dotfiles-channel-update@.+\.service|copy-cache-li7g-com@.+\.service').test(action.lookup("unit")) === true &&
          subject.isInGroup("hydra")) {
        return polkit.Result.YES;
      }
    });
  '';
}
