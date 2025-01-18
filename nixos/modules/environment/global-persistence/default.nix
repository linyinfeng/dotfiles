{
  config,
  lib,
  pkgs,
  ...
}:
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

  mkUserCfg =
    name:
    assert config.home-manager.users.${name}.home.global-persistence.enabled;
    {
      inherit name;
      value = {
        inherit (config.home-manager.users.${name}.home.global-persistence) home directories files;
      };
    };
  usersCfg = lib.listToAttrs (map mkUserCfg cfg.user.users);

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
      inherit (config.home-manager.users.${name}.home.global-persistence) home directories files;
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

  userTmpFilesCfg = lib.listToAttrs (lib.concatLists (map mkUserTmpFilesCfg cfg.user.users));
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
    preservation.enable = true;
    preservation.preserveAt.${cfg.root} = {
      inherit (cfg) directories files;
      users = usersCfg;
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
