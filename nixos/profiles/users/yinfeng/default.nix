{
  config,
  pkgs,
  lib,
  ...
}: let
  name = "yinfeng";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent = name:
    lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
in {
  imports = [
    ./_syncthing
  ];

  users.users.${name} = {
    inherit uid;
    hashedPasswordFile = config.sops.secrets."user-password/${name}".path;
    isNormalUser = true;
    shell = pkgs.fish;
    home = homeDirectory;
    extraGroups = with config.users.groups;
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
      ++ groupNameIfPresent "wireshark";

    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/${name}" = {
    neededForUsers = true;
    sopsFile = config.sops-file.get "common.yaml";
  };

  environment.global-persistence.user.users = [name];
  home-manager.users.${name} = {
    suites,
    profiles,
    ...
  }: {
    imports = [profiles.atuin];
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

  # extra secrets
  sops.secrets."atuin_password_${name}" = {
    terraformOutput.enable = true;
    owner = name;
    group = config.users.users.${name}.group;
  };
}
