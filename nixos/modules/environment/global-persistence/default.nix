{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.environment.global-persistence;
  scripts = pkgs.buildEnv {
    name = "global-persistence-scripts";
    paths = [
      migrateToPersist
      persistPermission
    ];
  };
  migrateToPersist = pkgs.writeShellApplication {
    name = "persist-migrate";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      rsync
    ];
    text = ''
      persist='${cfg.root}'

      NC='\033[0m'
      function output {
        GREEN='\033[0;32m'
        printf "$GREEN-- %s$NC\n" "$@"
      }

      function failure {
        RED='\033[0;31m'
        printf "$RED-- %s$NC\n" "$@"
      }

      for file in "$@"; do
        source=$(realpath "$file")
        if [ ! -e "$source" ]; then
          failure "file does not exists: '$source'"
          exit 1
        fi

        # shellcheck disable=SC2016
        filesystem=$(df --portability "$source" | awk 'NR==2{print$6}')
        if [ ! "$filesystem" = "/" ]; then
          output "file is not on filesystem '/': '$source'"
          exit 0
        fi

        target="$persist$source"

        if [ -d "$source" ]; then
          rsync_source="$source/"
        else
          rsync_source="$source"
        fi
        output "mkdir -p $(dirname "$target")"
        mkdir -p "$(dirname "$target")"
        output "migrate '$source' to '$target'"
        rsync --archive --recursive --progress --delete --compress \
          "$rsync_source" "$target"
        output "migration of '$source' finished"
      done
    '';
  };
  persistPermission = pkgs.writeShellApplication {
    name = "persist-permission";
    runtimeInputs = with pkgs; [
      fd
    ];
    text = ''
      persist="${cfg.root}"

      uid=$(id --user)
      gid=$(id --group)

      fd \
        --hidden \
        --type directory \
        --owner "!$uid:!$gid" \
        . "$persist$HOME" "$@"
    '';
  };

  hasHm = name: config.home-manager.users ? ${name};
  hmCfg = name: config.home-manager.users.${name}.home.global-persistence;

  # user.users is the only authority: it may name users without a home-manager config
  # (system users), so the path comes from the NixOS side and the HM side only adds entries.
  persistedDirs = name: lib.optionals (hasHm name) (hmCfg name).directories ++ cfg.user.directories;
  persistedFiles = name: lib.optionals (hasHm name) (hmCfg name).files ++ cfg.user.files;

  knownUsers = lib.filter (name: config.users.users ? ${name}) cfg.user.users;
  unknownUsers = lib.subtractLists knownUsers cfg.user.users;

  mkUserCfg = name: {
    inherit name;
    value = {
      home = config.users.users.${name}.home;
      directories = persistedDirs name;
      files = persistedFiles name;
    };
  };
  usersCfg = lib.listToAttrs (map mkUserCfg knownUsers);

  parentDir =
    path:
    let
      components = lib.splitString "/" path;
      front = lib.take (lib.length components - 1) components;
    in
    lib.concatStringsSep "/" front;

  parentDirs = paths: parentNormalize (map parentDir paths);

  parentNormalize = paths: lib.sort builtins.lessThan (lib.remove "" (lib.unique paths));

  parentClosure =
    paths:
    let
      iter = parentNormalize (paths ++ parentDirs paths);
    in
    if iter == paths then iter else parentClosure iter;

  mkUserTmpFilesCfg =
    name:
    let
      home = config.users.users.${name}.home;
      directories = persistedDirs name;
      files = persistedFiles name;
      userCfg = config.users.users.${name};
      parents = parentClosure (parentDirs (directories ++ files));
      parentsWithHome = map (p: "${home}/${p}") parents;
    in
    map (path: {
      name = path;
      value = {
        d = {
          user = userCfg.name;
          inherit (userCfg) group;
          mode = "0755";
        };
      };
    }) parentsWithHome;

  userTmpFilesCfg = lib.listToAttrs (lib.concatLists (map mkUserTmpFilesCfg knownUsers));
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
      type = with types; listOf anything;
      default = [ ];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };

    files = mkOption {
      type = with types; listOf anything;
      default = [ ];
      description = ''
        Files should be stored in persistent storage.
      '';
    };

    persistMigrate = mkOption {
      type = with types; package;
      default = scripts;
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
    preservation.enable = true;

    home-manager.sharedModules = [
      ({ lib, ... }: {
        home.global-persistence.root = lib.mkDefault cfg.root;
      })
    ];

    warnings =
      map (
        name: "environment.global-persistence: '${name}' in user.users is not a defined user; ignored"
      ) unknownUsers
      ++ lib.concatMap (
        name:
        lib.optional
          (
            config.users.users.${name}.home == "/var/empty" && persistedDirs name ++ persistedFiles name != [ ]
          )
          "environment.global-persistence: user '${name}' has home = /var/empty; relative entries are created there, use environment.global-persistence.directories for absolute paths"
        ++
          lib.optional (hasHm name && !(hmCfg name).enable)
            "environment.global-persistence: user '${name}' is persisted while home.global-persistence.enable is false"
      ) knownUsers;

    preservation.preserveAt.${cfg.root} = {
      inherit (cfg) directories files;
      users = usersCfg;
      commonMountOptions = [
        "x-gvfs-hide"
        "x-gdu.hide"
      ];
    };

    systemd.tmpfiles.settings."10-preservation" = userTmpFilesCfg // {
      ${cfg.root} = {
        d = {
          user = "root";
          group = "root";
          mode = "0755";
        };
      };
    };

    environment.systemPackages = [ cfg.persistMigrate ];

    # for user level persistence
    programs.fuse.userAllowOther = true;

    passthru = { inherit userTmpFilesCfg; };
  };
}
