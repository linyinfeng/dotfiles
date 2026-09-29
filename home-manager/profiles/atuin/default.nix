{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretPaths = config.home.env.secretPaths;

  atuinLogin = pkgs.writeShellApplication {
    name = "atuin-login";
    runtimeInputs = with pkgs; [
      coreutils
      config.programs.atuin.package
    ];
    text = ''
      set -x
      if [[ "$(atuin status)" =~ "not logged in" ]]; then
        atuin login \
          --username yinfeng \
          --password "$(cat "${secretPaths.atuin_password_yinfeng}")" \
          --key "" # use existing key
      fi
      atuin status
    '';
  };
in
lib.mkIf (secretPaths ? yinfeng_atuin_key) {
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      update_check = false;
      enter_accept = true;
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.li7g.com";
      key_path = secretPaths.yinfeng_atuin_key;
    };
  };

  systemd.user.services.atuin-login = lib.mkIf (secretPaths ? atuin_password_yinfeng) {
    Service = {
      Environment = lib.mkIf config.home.env.proxy.enable config.home.env.proxy.stringEnvironment;
      ExecStart = "${atuinLogin}/bin/atuin-login";
      Type = "oneshot";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.global-persistence.directories = [ ".local/share/atuin" ];
}
