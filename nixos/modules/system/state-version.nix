{
  config,
  options,
  lib,
  ...
}: let
  targetStateVersion = config.lib.self.flakeStateVersion;

  cfg = config.system;
in {
  options = {
    system.targetStateVersion = lib.mkOption {
      inherit (options.system.stateVersion) type;
      description = ''
        System is going to be upgraded to the targetStateVersion.
      '';
    };
    system.pendingStateVersionUpgrade = lib.mkOption {
      type = lib.types.bool;
      default = cfg.stateVersion != cfg.targetStateVersion;
      readOnly = true;
    };
  };
  config = {
    system = {
      inherit targetStateVersion;
    };
    specialisation = lib.mkIf cfg.pendingStateVersionUpgrade {
      target-state-version = {
        configuration = {
          system.stateVersion = lib.mkForce targetStateVersion;
        };
      };
    };
    warnings = lib.mkIf cfg.pendingStateVersionUpgrade [
      # add empty line to highlight this warning
      ''


        host: ${config.networking.hostName}
        pending stateVersion upgrade from ${cfg.stateVersion} to ${cfg.targetStateVersion}
        release notes: https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-${cfg.targetStateVersion}
      ''
    ];
  };
}
