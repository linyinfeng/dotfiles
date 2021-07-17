{ hmUsers, ... }:
{
  home-manager.users = { inherit (hmUsers) nixos; };

  users.users.nixos = {
    uid = 2000;
    password = "nixos";
    description = "default";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
