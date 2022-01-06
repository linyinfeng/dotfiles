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
      git checkout main && git reset --hard "$1"
      git push --force origin main:tested
    '';
    scriptArgs = "%I";
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

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "dotfiles-channel-update@.service" &&
        subject.group == "hydra") {
        return polkit.Result.YES;
      }
    });
  '';

  environment.global-persistence.directories = [
    "/var/lib/private/dotfiles-channel-update"
  ];
}
