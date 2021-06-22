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
    passwordFile = config.age.secrets."user-${name}-password".path;
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
    ] ++
    lib.optional (config.users.groups ? transmission) config.users.groups.transmission.name;

    openssh.authorizedKeys.keyFiles =
      config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  age.secrets = {
    "user-${name}-password".file = ../../secrets + "/user-${name}-password.age";
    "${name}-asciinema-token" = {
      file = ../../secrets + "/${name}-asciinema-token.age";
      owner = user.name;
    };
    "${name}-id-ed25519" = {
      file = ../../secrets + "/${name}-id-ed25519.age";
      owner = user.name;
    };
    "${name}-nix-access-tokens" = {
      file = ../../secrets + "/${name}-nix-access-tokens.age";
    };
  };

  age.templates."${name}-nix-conf" = {
    content = ''
      access-tokens = ${config.age.placeholder."${name}-nix-access-tokens"}
    '';
    owner = user.name;
  };

  home-manager.users.${name} = { suites, ... }: {
    imports = suites.full;

    home.global-persistence.enable = true;

    home.linkSecrets.".ssh/id_ed25519".secret = config.age.secrets."${name}-id-ed25519".path;
    home.linkSecrets.".config/nix/nix.conf".secret = config.age.templates."${name}-nix-conf".path;
    home.file.".ssh/id_ed25519.pub".source = ./ssh/id_ed25519.pub;
    home.file.".ssh/config".source = ./ssh/config;

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
