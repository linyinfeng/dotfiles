{ config, pkgs, lib, ... }:

let
  cfg = config.services.clean-gcroots;
in

with lib;
{
  options.services.clean-gcroots = {
    enable = mkOption
      {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable clean-gcroots service for users.
        '';
      };
  };
  config = mkIf (cfg.enable) {
    systemd.user.services.clean-gcroots = {
      description = "Clean user gcroots";
      script = ''
        user="$1"
        ${pkgs.findutils}/bin/find -L "/nix/var/nix/gcroots/per-user/$user" -maxdepth 1 -type l -delete -print
      '';
      scriptArgs = "%u";
      serviceConfig = {
        Type = "oneshot";
      };
    };
    systemd.user.timers.clean-gcroots = {
      description = "Timer for clean-gcroots";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
