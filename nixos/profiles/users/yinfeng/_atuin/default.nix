{ config, ... }:
{
  home-manager.users.yinfeng =
    {
      osConfig,
      config,
      pkgs,
      ...
    }:
    {
      programs.atuin = {
        enable = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          update_check = false;
          enter_accept = true;
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "https://atuin.ts.li7g.com";
          key_path = osConfig.sops.secrets."yinfeng_atuin_key".path;
        };
      };
      systemd.user.services.atuin-login = {
        Service =
          let
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
                    --password "$(cat "${osConfig.sops.secrets."atuin_password_yinfeng".path}")" \
                    --key "" # use existing key
                fi
                atuin status
              '';
            };
          in
          {
            ExecStart = "${atuinLogin}/bin/atuin-login";
            Type = "oneshot";
            Restart = "on-failure";
          };
        Install.WantedBy = [ "default.target" ];
      };
      home.global-persistence.directories = [ ".local/share/atuin" ];
    };
  sops.secrets."atuin_password_yinfeng" = {
    terraformOutput.enable = true;
    owner = "yinfeng";
    inherit (config.users.users.yinfeng) group;
  };
  sops.secrets."yinfeng_atuin_key" = {
    predefined.enable = true;
    owner = "yinfeng";
    inherit (config.users.users.yinfeng) group;
  };
}
