{ config, pkgs, lib, ... }:

let
  name = "yinfeng";
  uid = config.ids.uids.${name};
  user = config.users.users.${name};
  homeManager = config.home-manager.users.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent = name: lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
in
{
  imports = [
    ./syncthing
  ];

  users.users.${name} = {
    inherit uid;
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
    groupNameIfPresent "tss" ++
    groupNameIfPresent "nix-access-tokens" ++
    groupNameIfPresent "nixbuild" ++
    groupNameIfPresent "telegram-send" ++
    groupNameIfPresent "service-mail" ++
    groupNameIfPresent "plugdev" ++
    groupNameIfPresent "acme" ++
    groupNameIfPresent "windows";

    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  sops.secrets."user-password/${name}" = {
    neededForUsers = true;
    sopsFile = config.sops.secretsDir + /common.yaml;
  };

  environment.global-persistence.user.users = [ name ];
  home-manager.users.${name} = { suites, ... }: {
    imports = suites.full;
    home.global-persistence = {
      enable = true;
      home = homeDirectory;
    };

    home.file.".ssh/config".source = pkgs.substituteAll {
      src = ./ssh/config;
      inherit uid;
    };

    programs.git = {
      userName = "Lin Yinfeng";
      userEmail = "lin.yinfeng@outlook.com";
      # do not sign by default
      # signing.signByDefault = true;
    };
    programs.gpg.publicKeys = [
      {
        source = ./pgp/pub.asc;
        trust = "ultimate";
      }
    ];

    # TODO a service for debug
    systemd.user.services.user-units-debug =
      let
        script = pkgs.writeShellScript "user-units-debug" ''
          set -e
          export PATH="${pkgs.coreutils}/bin:$PATH"
          export PATH="${pkgs.systemd}/bin:$PATH"
          while true; do
            echo "units report -- failed"
            systemctl --user list-units --failed
            echo "units report -- jobs"
            systemctl --user list-jobs --full
            sleep 60
          done
        '';
      in
      {
        Service.ExecStart = "${script}";
        Install.WantedBy = [ "default.target" ];
      };
  };

  environment.etc."nixos".source = "${homeDirectory}/Source/dotfiles";
}
