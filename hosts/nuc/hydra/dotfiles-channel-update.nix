{ config, lib, pkgs, ... }:

{
  systemd.services."dotfiles-channel-update@" = {
    script = ''
      cd "$STATE_DIRECTORY"
      commit="$1"

      # push cache to cachix
      export CACHIX_SIGNING_KEY=$(cat "$CREDENTIALS_DIRECTORY/cachix-signing-key")
      export HOME="$STATE_DIRECTORY"
      for host in vultr nexusbytes x200s; do
        echo "push cache for host: $host"
        nix build "github:linyinfeng/dotfiles/$commit#nixosConfigurations.$host.config.system.build.toplevel" --json | \
          jq ".[].outputs.out" --raw-output | \
          cachix push linyinfeng
      done

      # update channel
      if [ ! -d dotfiles ]; then
        git clone https://github.com/linyinfeng/dotfiles.git
        pushd dotfiles
        token=$(cat "$CREDENTIALS_DIRECTORY/github-token")
        git remote set-url origin "http://littlenano:$token@github.com/linyinfeng/dotfiles.git"
        popd
      fi
      cd dotfiles
      git checkout tested || git checkout -b tested
      git pull origin tested
      git fetch
      git merge --ff-only "$commit"
      git push --set-upstream origin tested
    '';
    scriptArgs = "%I";
    path = with pkgs; [
      git nixUnstable cachix jq
    ];
    serviceConfig = {
      DynamicUser = true;
      Group = "hydra";
      StateDirectory = "dotfiles-channel-update";
      LoadCredential = [
        "github-token:${config.sops.secrets."nano/github-token".path}"
        "cachix-signing-key:${config.sops.secrets."cachix/linyinfeng".path}"
      ];
    };
    environment = lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
  };
  sops.secrets."nano/github-token" = { };
  sops.secrets."cachix/linyinfeng" = { };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          RegExp('dotfiles-channel-update@[A-Za-z0-9_-]+.service').test(action.lookup("unit")) === true &&
          subject.isInGroup("hydra")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.global-persistence.directories = [
    "/var/lib/private/dotfiles-channel-update"
  ];
}
