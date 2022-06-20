{ config, pkgs, lib, utils, ... }:

let
  scrubCfg = config.services.btrfs.autoScrub;
  makeServiceAndTimerCfg = fs:
    let
      fs' = utils.escapeSystemdPath fs;
    in
    lib.nameValuePair "btrfs-scrub-resume-${fs'}" {
      serviceCfg = {
        description = "btrfs scrub auto resume service for ${fs}";
        script = ''
          echo "checking status..."
          status=$(btrfs scrub status "${fs}")
          echo "$status"
          if echo "$status" | grep "^Status:.*aborted$"; then
            echo "resuming scrub for ${fs}..."
            systemctl start "btrfs-scrub-${fs'}.service"
          else
            echo "no need to resume scrub for ${fs}"
          fi
        '';
        path = with pkgs; [ btrfs-progs gnugrep ];
        serviceConfig = {
          Type = "oneshot";
        };
      };

      timerCfg = {
        description = "btrfs scrub auto resume timer for ${fs}";
        timerConfig.OnBootSec = "1min";
        wantedBy = [ "multi-user.target" ];
      };
    };

  makeServiceOverride = fs:
    let
      fs' = utils.escapeSystemdPath fs;
      startOrResume = pkgs.writeShellScript "btrfs-scrub-start-or-resume" ''
        set -e
        echo "checking status..."
        status=$(btrfs scrub status "${fs}")
        echo "$status"
        if echo "$status" | grep "^Status:.*aborted$"; then
          echo "resuming scrub for ${fs}..."
          btrfs scrub resume -B "${fs}"
        else
          echo "starting scrub for ${fs}..."
          btrfs scrub start -B "${fs}"
        fi
      '';
    in
    lib.nameValuePair "btrfs-scrub-${fs'}" {
      serviceConfig.ExecStart = lib.mkForce startOrResume;
      path = with pkgs; [ btrfs-progs gnugrep ];
    };

  cfgs = lib.listToAttrs (map makeServiceAndTimerCfg scrubCfg.fileSystems);
in
lib.mkIf (scrubCfg.enable) {
  systemd.services = lib.mapAttrs (_name: cfg: cfg.serviceCfg) cfgs //
    lib.listToAttrs (map makeServiceOverride scrubCfg.fileSystems);
  systemd.timers = lib.mapAttrs (_name: cfg: cfg.timerCfg) cfgs;
}
