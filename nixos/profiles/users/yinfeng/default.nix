{
  config,
  pkgs,
  lib,
  ...
}:
let
  name = "yinfeng";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent =
    name: lib.optional (config.users.groups ? ${name}) config.users.groups.${name}.name;
in
{
  imports = [
    ./_syncthing
    ./_atuin
  ];

  users.users.${name} = {
    inherit uid;
    hashedPasswordFile = config.sops.secrets."user-password/${name}".path;
    isNormalUser = true;
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups =
      with config.users.groups;
      [
        users.name
        wheel.name
        keys.name
      ]
      ++ groupNameIfPresent "adbusers"
      ++ groupNameIfPresent "video"
      ++ groupNameIfPresent "libvirtd"
      ++ groupNameIfPresent "transmission"
      ++ groupNameIfPresent "networkmanager"
      ++ groupNameIfPresent "tss"
      ++ groupNameIfPresent "nix-access-tokens"
      ++ groupNameIfPresent "nixbuild"
      ++ groupNameIfPresent "hydra-builder-client"
      ++ groupNameIfPresent "tg-send"
      ++ groupNameIfPresent "service-mail"
      ++ groupNameIfPresent "plugdev"
      ++ groupNameIfPresent "acme"
      ++ groupNameIfPresent "acmetf"
      ++ groupNameIfPresent "windows"
      ++ groupNameIfPresent "wireshark"
      ++ groupNameIfPresent "feedbackd";

    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/${name}" = {
    neededForUsers = true;
    sopsFile = config.sops-file.get "common.yaml";
  };

  environment.global-persistence.user.users = [ name ];
  home-manager.users.${name} =
    { ... }:
    {
      home.global-persistence = {
        enable = true;
        home = homeDirectory;
      };

      programs.git = {
        userName = "Lin Yinfeng";
        userEmail = "lin.yinfeng@outlook.com";
        # do not sign by default
        # signing.signByDefault = true;
      };
      programs.gpg.publicKeys = [
        {
          source = ./_pgp/pub.asc;
          trust = "ultimate";
        }
      ];
    };

  environment.etc."nixos".source = "${homeDirectory}/Source/dotfiles";
  programs.nh.flake = "${homeDirectory}/Source/dotfiles";
}
