{ config, options, lib, pkgs, ... }:

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

  userCfg = name:
    assert config.home-manager.users.${name}.home.global-persistence.enabled;
    {
      inherit name;
      value = {
        inherit (config.home-manager.users.${name}.home.global-persistence)
          home directories files;
      };
    };
  usersCfg = lib.listToAttrs (map userCfg cfg.user.users);
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

    directories = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };

    files = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Files should be stored in persistent storage.
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
      users = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          Persistence for users.
        '';
      };

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
      inherit (cfg) directories files;
      users = usersCfg;
      hideMounts = true;
    };

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

    environment.systemPackages = [
      cfg.persistMigrate
    ];

    # for user level persistence
    programs.fuse.userAllowOther = true;
  };
}
