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
  groupNameIfPresent = config.lib.self.groupNameIfPresent config;
in
{
  imports = [
    ./_syncthing
    ./_atuin
  ];

  config = lib.mkMerge [
    {
      world.profiles.development.llm-keys.enable = lib.mkDefault true;
    }

    # basic
    {
      users.users.${name} = {
        inherit uid;
        hashedPasswordFile = config.sops.secrets."user_password_${name}".path;
        isNormalUser = true;
        autoSubUidGidRange = true;
        shell = pkgs.fish;
        home = homeDirectory;
        group = name; # private group
        extraGroups =
          with config.users.groups;
          [
            users.name
            wheel.name
            keys.name
            llm.name
          ]
          ++ groupNameIfPresent "audio"
          ++ groupNameIfPresent "video"
          ++ groupNameIfPresent "i2c"
          ++ groupNameIfPresent "input"
          ++ groupNameIfPresent "adbusers"
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
      users.groups.${name}.gid = uid; # private group, same as uid

      sops.secrets."user_password_${name}" = {
        predefined.enable = true;
        neededForUsers = true;
      };

      environment.global-persistence.user.users = [ name ];
      home-manager.users.${name}.home.global-persistence.enable = true;
    }
    # system administration
    {
      environment.etc."nixos".source = "${homeDirectory}/Projects/dotfiles";
      programs.nh.flake = "${homeDirectory}/Projects/dotfiles";
    }
  ];

}
