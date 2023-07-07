{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.services."dotfiles-channel-update@" = {
    script = ''
      cd "$STATE_DIRECTORY"

      update_file="$1"
      echo "update_file = $update_file"

      host=$(jq -r '.host' "$update_file")
      echo "host = $host"
      commit=$(jq -r '.commit' "$update_file")
      echo "commit = $commit"
      out=$(jq -r '.out' "$update_file")
      echo "out = $out"

      target_branch="nixos-tested-$host"
      echo "target_branch = $target_branch"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        systemctl start "copy-cache-li7g-com@$(systemd-escape "$out").service"

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
        git push origin "$commit:$target_branch" --verbose

        ${config.programs.tg-send.wrapped} <<EOF
      dotfiles/$target_branch

      $(git show HEAD --no-patch)
      EOF
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
      SupplementaryGroups = [
        config.users.groups.tg-send.name
      ];
      StateDirectory = "dotfiles-channel-update";
      Restart = "on-failure";
      LoadCredential = [
        "github-token:${config.sops.secrets."nano/github-token".path}"
      ];
    };
    environment =
      lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
  };
  sops.secrets."nano/github-token" = {
    sopsFile = config.sops-file.get "common.yaml";
    restartUnits = ["dotfiles-channel-update@.service"];
  };

  services.notify-failure.services = ["dotfiles-channel-update@"];

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
