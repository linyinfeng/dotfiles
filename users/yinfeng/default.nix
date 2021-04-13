{ config, pkgs, lib, ... }:

{
  users.users.yinfeng = {
    uid = 1000;
    hashedPassword = lib.removeSuffix "\n" (builtins.readFile ../../secrets/users/yinfeng/hashedPassword.txt);
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

    home.global-persistence.enable = true;

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
