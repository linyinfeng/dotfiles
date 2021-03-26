{ config, lib, pkgs, ... }:

let
  cfg = config.environment.global-persistence;
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

    environment.systemPackages = [
      (pkgs.stdenvNoCC.mkDerivation {
        name = "global-persistence-scripts";
        buildCommand = ''
          install -Dm755 $migrateToPersist $out/bin/persist-migrate
          install -Dm755 $persistPermission $out/bin/persist-permission
        '';
        migrateToPersist = pkgs.substituteAll {
          src = ./global-persistence/persist-migrate.sh;
          isExecutable = true;
          inherit (pkgs.stdenvNoCC) shell;
          inherit (pkgs) coreutils gawk rsync;
          persist = cfg.root;
        };
        persistPermission = pkgs.substituteAll {
          src = ./global-persistence/persist-permission.sh;
          isExecutable = true;
          inherit (pkgs.stdenvNoCC) shell;
          inherit (pkgs) fd;
          persist = cfg.root;
        };
      })
    ];

    # for user level persistence
    programs.fuse.userAllowOther = true;
  };
}
