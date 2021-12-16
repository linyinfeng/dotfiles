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
    passwordFile = config.sops.secrets."user-password/${name}".path;
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
    groupNameIfPresent "networkmanager" ++
    groupNameIfPresent "tss";

    openssh.authorizedKeys.keyFiles = [
      ./ssh/id_ed25519.pub
      ./ssh/authorized-keys/t460p-win.pub
    ];
  };

  sops.secrets = {
    "user-password/${name}".neededForUsers = true;
    "${name}/asciinema-token".owner = user.name;
    "${name}/id-ed25519".owner = user.name;
    "${name}/nix-access-tokens" = { };
  };
  sops.templates."${name}/nix-conf" = {
    content = ''
      access-tokens = ${config.sops.placeholder."${name}/nix-access-tokens"}
    '';
    owner = user.name;
  };

  home-manager.users.${name} = { suites, ... }: {
    imports = suites.full;

    passthrough.systemConfig = config;

    home.global-persistence.enable = true;

    home.link.".ssh/id_ed25519".target = config.sops.secrets."${name}/id-ed25519".path;
    home.link.".config/nix/nix.conf".target = config.sops.templates."${name}/nix-conf".path;
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
