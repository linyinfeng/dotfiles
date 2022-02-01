{ config, lib, pkgs, ... }:

let
  cfg = config.environment.global-persistence;
  persistMigrate = pkgs.stdenvNoCC.mkDerivation {
    name = "global-persistence-scripts";
    buildCommand = ''
      install -Dm755 $migrateToPersist $out/bin/persist-migrate
      install -Dm755 $persistPermission $out/bin/persist-permission
    '';
    migrateToPersist = pkgs.substituteAll {
      src = ./persist-migrate.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) coreutils gawk rsync;
      persist = cfg.root;
    };
    persistPermission = pkgs.substituteAll {
      src = ./persist-permission.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) fd;
      persist = cfg.root;
    };
  };
  activationScriptName = "createPersistentStorageDirs";
in

with lib;
{
  options.environment.global-persistence = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable global persistence storage.
      '';
    };

    root = lib.mkOption {
      type = with types; nullOr str;
      description = ''
        The root of persistence storage.
      '';
    };

    etcFiles = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Files in /etc that should be stored in persistent storage.
      '';
    };

    directories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };

    softLinkFiles = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Files should be stored in persistent storage. These files will be soft linked.
      '';
    };

    persistMigrate = mkOption {
      type = with types; package;
      default = persistMigrate;
      description = ''
        persist-migrate script.
      '';
    };

    user = {
      directories = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Directories to bind mount to persistent storage for users.
          Paths should be relative to home of user.
        '';
      };

      files = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Files to link to persistent storage for users.
          Paths should be relative to home of user.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.root != null) {
    environment.persistence.${cfg.root} = {
      directories = cfg.directories;
      files = cfg.etcFiles;
    };

    system.activationScripts.globalPersistenceLinkFiles =
      let
        link = file:
          ''
            link "${file}"
          '';
        links = concatMapStrings link cfg.softLinkFiles;
        script = pkgs.writeShellScript "global-persistence-link-files"
          ''
            function link() {
              mkdir -p $(dirname "/$1")
              mkdir -p $(dirname "${cfg.root}/$1")
              ln -sf "${cfg.root}/$1" "/$1"
            }
            ${links}
          '';
      in
      "${script}";
    system.activationScripts.ensurePersistenceRootExists = {
      text = ''
        if [ ! -d "${cfg.root}" ]; then
          echo "Warning: global persistence storage '${cfg.root}' is not presented, create a fake one for test only."
          mkdir -p "${cfg.root}"
        fi
      '';
    };
    system.activationScripts.${activationScriptName}.deps =
      [ "ensurePersistenceRootExists" ];
    systemd.services.fix-home-permission = {
      script =
        let
          enableFilter = user: _:
            config.home-manager.users ? ${user} &&
            config.home-manager.users.${user}.home.global-persistence.enable;
          enabledUsers = lib.filterAttrs enableFilter config.users.users;
          fixScript = user: userCfg: ''
            echo "try fix for ${user}"
            if [ $(stat --format='%U:%G' "${cfg.root}${userCfg.home}") != "${userCfg.name}:${userCfg.group}" ]; then
              echo "change permission of ${cfg.root}${userCfg.home} to ${userCfg.name}:${userCfg.group}..."
              chown -R ${userCfg.name}:${userCfg.group} "${cfg.root}${userCfg.home}"
            fi
          '';
        in
        lib.concatStrings (lib.mapAttrsToList fixScript enabledUsers);
      wantedBy = [ "multi-user.target" ];
    };

    age.identityPaths = [
      "${cfg.root}/etc/ssh/ssh_host_ed25519_key"
    ];

    environment.systemPackages = [
      cfg.persistMigrate
    ];

    # for user level persistence
    programs.fuse.userAllowOther = true;
  };
}
