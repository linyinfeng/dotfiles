{ config, pkgs, lib, ... }:

{
  users.users.yinfeng = {
    uid = 1000;
    hashedPassword =
      "$6$h301rApi$UNvaI1rdGSQPKG.pBOv0W941dKKDiUUexVVrLE7dO5oJEO5fp72.z7Eg/aZIsI0nzJJrQuEKw0IeaO0Zrcxmp/";
    isNormalUser = true;
    shell = pkgs.fish;
    group = config.users.groups.yinfeng.name;
    extraGroups = with config.users.groups; [
      users.name
      wheel.name
      networkmanager.name
      adbusers.name
      docker.name
      libvirtd.name
      keys.name
    ];
  };

  users.groups.yinfeng = {
    gid = 1000;
  };

  sops.secrets = {
    yinfeng-asciinema-token = {
      owner = "yinfeng";
    };
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
