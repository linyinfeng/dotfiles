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
      script = "${pkgs.findutils}/bin/find -L /nix/var/nix/gcroots/per-user/%u -maxdepth 1 -type l -delete -print";
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
