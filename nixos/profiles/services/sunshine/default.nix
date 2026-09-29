{ config, ... }:
let
  inherit (config.networking) hostName;
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      # port = 47989; # simply use default port
      sunshine_name = hostName;
      address_family = "both";
      origin_web_ui_allowed = "pc"; # localhost only
      credentials_file = config.sops.secrets."sunshine_credentials_file".path;
    };
  };
  sops.secrets."sunshine_credentials_file" = {
    predefined.enable = true;
    # credentials are hashed, simply make it available to all users
    mode = "440";
    group = config.users.groups.users.name;
  };
}
