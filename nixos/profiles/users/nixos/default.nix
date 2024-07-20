{ config, ... }:
{
  home-manager.users.nixos =
    { suites, ... }:
    {
      imports = suites.base;
    };

  users.users.nixos = {
    uid = config.ids.uids.nixos;
    password = "nixos";
    description = "default";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
