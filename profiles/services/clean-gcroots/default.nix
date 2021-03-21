{ pkgs, ... }:

{
  systemd.user.services.clean-gcroots = {
    description = "Clean user gcroots";
    script = "${pkgs.findutils}/bin/find -L /nix/var/nix/gcroots/per-user/%u -maxdepth 1 -type l -delete -print";
    serviceConfig = {
      Type = "oneshot";
    };
    wantedBy = [ "default.target" ];
  };
  systemd.user.timers.clean-gcroots = {
    description = "Timer for clean-gcroots";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
