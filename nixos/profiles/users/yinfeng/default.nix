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

  config = lib.mkMerge [
    # basic
    {
      users.users.${name} = {
        inherit uid;
        hashedPasswordFile = config.sops.secrets."user_password_${name}".path;
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
        group = name; # private group
        extraGroups =
          with config.users.groups;
          [
            users.name
            wheel.name
            keys.name
          ]
          ++ groupNameIfPresent "audio"
          ++ groupNameIfPresent "video"
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
      home-manager.users.${name}.home.global-persistence = {
        enable = true;
        home = homeDirectory;
      };
    }
    # git and gpg
    {
      home-manager.users.${name} = {
        programs.git.settings = {
          user.name = "Lin Yinfeng";
          user.email = "lin.yinfeng@outlook.com";
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
    }

    # claude-code
    {
      home-manager.users.yinfeng.programs.fish.interactiveShellInit = ''
        export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$(cat "${config.sops.secrets."deepseek_api_key".path}")"
        export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
        export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
        export CLAUDE_CODE_EFFORT_LEVEL="max"
      '';
      sops.secrets."deepseek_api_key" = {
        predefined.enable = true;
        restartUnits = [ ];
        owner = name;
      };
    }

    # gemini-cli
    {
      home-manager.users.yinfeng.programs.fish.interactiveShellInit = ''
        export GEMINI_API_KEY="$(cat "${config.sops.secrets."gemini_api_key".path}")"
      '';
      sops.secrets."gemini_api_key" = {
        predefined.enable = true;
        restartUnits = [ ];
        owner = name;
      };
    }

    # system administration
    {
      environment.etc."nixos".source = "${homeDirectory}/Source/dotfiles";
      programs.nh.flake = "${homeDirectory}/Source/dotfiles";
    }
  ];

}
