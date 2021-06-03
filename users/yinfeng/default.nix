{ config, pkgs, lib, ... }:

let
  name = "yinfeng";
  user = config.users.users.${name};
  homeManager = config.home-manager.users.${name};
  homeDirectory = "/home/${name}";
in
{
  users.users.${name} = {
    uid = 1000;
    hashedPassword =
      "$6$h301rApi$UNvaI1rdGSQPKG.pBOv0W941dKKDiUUexVVrLE7dO5oJEO5fp72.z7Eg/aZIsI0nzJJrQuEKw0IeaO0Zrcxmp/";
    isNormalUser = true;
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups = with config.users.groups; [
      users.name
      wheel.name
      networkmanager.name
      adbusers.name
      docker.name
      libvirtd.name
      keys.name
    ];

    openssh.authorizedKeys.keyFiles =
      config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets = {
    "${name}-asciinema-token" = {
      owner = user.name;
    };
    "${name}-id-ed25519" = {
      owner = user.name;
      format = "binary";
      sopsFile = ../../sops/ssh/id_ed25519.json;
    };
  };

  home-manager.users.${name} = { suites, ... }: {
    imports = suites.full;

    home.global-persistence.enable = true;

    home.linkSecrets.".ssh/id_ed25519".secret = config.sops.secrets."${name}-id-ed25519".path;
    home.file.".ssh/id_ed25519.pub".source = ../../sops/ssh/id_ed25519.pub;
    home.file.".ssh/config".source = ../../sops/ssh/config;

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

  environment.global-persistence.directories =
    map (dir: "${homeDirectory}/${dir}")
      homeManager.home.global-persistence.directories;
}
