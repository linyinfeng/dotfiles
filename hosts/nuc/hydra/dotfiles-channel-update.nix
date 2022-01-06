{ config, lib, pkgs, ... }:

{
  systemd.services."dotfiles-channel-update@" = {
    script = ''
      cd "$STATE_DIRECTORY"
      if [ ! -d dotfiles ]; then
        git clone https://github.com/linyinfeng/dotfiles.git
        pushd dotfiles
        token=$(cat "$CREDENTIALS_DIRECTORY/github-token")
        git remote set-url origin "http://littlenano:$token@github.com/linyinfeng/dotfiles.git"
        popd
      fi
      cd dotfiles
      git fetch
      git checkout main && git reset --hard %I
      git push --force origin main:tested
    '';
    path = with pkgs; [
      git
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "dotfiles-channel-update";
      LoadCredential = [
        "github-token:${config.sops.secrets."hydra/github-token".path}"
      ];
    };
    environment = lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
  };
  sops.secrets."hydra/github-token" = { };

  environment.global-persistence.directories = [
    "/var/lib/private/dotfiles-channel-update"
  ];
}
