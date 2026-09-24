{ config, ... }:
{
  home-manager.users.nixos =
    { lib, ... }:
    {
      world.suites.base.enable = lib.mkDefault true;
    };

  users.users.nixos = {
    uid = config.ids.uids.nixos;
    password = "nixos";
    description = "default";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
