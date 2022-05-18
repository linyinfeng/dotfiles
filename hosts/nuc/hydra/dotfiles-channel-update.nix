{ config, lib, pkgs, ... }:

{
  systemd.services."dotfiles-channel-update@" = {
    script = ''
      cd "$STATE_DIRECTORY"
      commit="$1"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        systemctl start copy-cache-li7g-com.service

        # push cache to cachix
        export CACHIX_SIGNING_KEY=$(cat "$CREDENTIALS_DIRECTORY/cachix-signing-key")
        export HOME="$STATE_DIRECTORY"
        for host in vultr nexusbytes aws; do
          echo "push cache to cachix for host: $host"
          nix build "github:linyinfeng/dotfiles/$commit#nixosConfigurations.$host.config.system.build.toplevel" --json | \
            jq ".[].outputs.out" --raw-output | \
            cachix push linyinfeng
        done

        # update channel
        if [ ! -d dotfiles ]; then
          git clone https://github.com/linyinfeng/dotfiles.git
          pushd dotfiles
          token=$(cat "$CREDENTIALS_DIRECTORY/github-token")
          git remote set-url origin "https://littlenano:$token@github.com/linyinfeng/dotfiles.git"
          popd
        fi
        cd dotfiles
        git checkout tested || git checkout -b tested
        git pull origin tested
        git fetch
        git merge --ff-only "$commit"
        git push --set-upstream origin tested

        ${config.programs.telegram-send.withConfig} --stdin <<EOF
      dotfiles/tested

      $(git show HEAD --no-patch)
      EOF
      ) 200>/var/lib/dotfiles-channel-update/lock
    '';
    scriptArgs = "%I";
    path = with pkgs; [
      git
      cachix
      jq
      config.nix.package
      util-linux
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      SupplementaryGroups = [
        config.users.groups.telegram-send.name
      ];
      StateDirectory = "dotfiles-channel-update";
      LoadCredential = [
        "github-token:${config.sops.secrets."nano/github-token".path}"
        "cachix-signing-key:${config.sops.secrets."cachix/linyinfeng".path}"
      ];
    };
    environment = (lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment);
  };
  sops.secrets."nano/github-token".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."cachix/linyinfeng".sopsFile = config.sops.secretsDir + /nuc.yaml;

  services.notify-failure.services = [ "dotfiles-channel-update@" ];

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          RegExp('dotfiles-channel-update@[A-Za-z0-9_-]+\.service|copy-cache-li7g-com\.service').test(action.lookup("unit")) === true &&
          subject.isInGroup("hydra")) {
        return polkit.Result.YES;
      }
    });
  '';
}
