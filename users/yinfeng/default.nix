{ config, pkgs, ... }:

{
  users.users.yinfeng = {
    uid = 1000;
    hashedPassword = import ../../secrets/users/yinfeng/hashedPassword.nix;
    isNormalUser = true;
    shell = pkgs.zsh;
    group = "yinfeng";
    extraGroups = [
      "users"
      "wheel"
      "networkmanager"
      "adbusers"
      "docker"
      "libvirtd"
    ];
  };

  users.groups.yinfeng = {
    gid = 1000;
  };

  home-manager.users.yinfeng = { suites, ... }: {
    imports = suites.full;

    programs.git = {
      userName = "Lin Yinfeng";
      userEmail = "lin.yinfeng@outlook.com";
      signing = {
        key = "35977ED3D1FB6D74484647F65FE6190217C55B26";
        signByDefault = true;
      };
    };

    passthrough.systemConfig = config;
  };
}
