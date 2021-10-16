{ config, pkgs, lib, ... }:

let
  name = "yinfeng";
  user = config.users.users.${name};
  homeManager = config.home-manager.users.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent = name: lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
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
      keys.name
    ] ++
    groupNameIfPresent "adbusers" ++
    groupNameIfPresent "libvirtd" ++
    groupNameIfPresent "transmission" ++
    groupNameIfPresent "networkmanager";

    openssh.authorizedKeys.keyFiles = [
      ./ssh/id_ed25519.pub
      ./ssh/authorized-keys/t460p-win.pub
    ];
  };

  age.secrets = {
    "user-${name}-password".file = config.age.secrets-directory + "/user-${name}-password.age";
    "${name}-asciinema-token" = {
      file = config.age.secrets-directory + "/${name}-asciinema-token.age";
      owner = user.name;
    };
    "${name}-id-ed25519" = {
      file = config.age.secrets-directory + "/${name}-id-ed25519.age";
      owner = user.name;
    };
    "${name}-nix-access-tokens" = {
      file = config.age.secrets-directory + "/${name}-nix-access-tokens.age";
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

    passthrough.systemConfig = config;

    home.global-persistence.enable = true;

    home.link.".ssh/id_ed25519".target = config.age.secrets."${name}-id-ed25519".path;
    home.link.".config/nix/nix.conf".target = config.age.templates."${name}-nix-conf".path;
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
  };

  environment.etc."nixos".source = "${homeDirectory}/Source/dotfiles";

  environment.global-persistence.directories =
    map (dir: "${homeDirectory}/${dir}")
      homeManager.home.global-persistence.directories;
}
