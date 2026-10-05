{ config, ... }:
let
  inherit (config.networking) hostName;
in
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      env = { };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
      ];
    };
    settings = {
      sunshine_name = hostName;
      address_family = "both";
      origin_web_ui_allowed = "pc"; # localhost only
      capture = "kms";
    };
  };
}
