{ pkgs, lib, ... }:
{
  services.udev.packages = with pkgs; [ logitech-udev-rules ];
  environment.systemPackages = with pkgs; [ solaar ];
  environment.global-persistence.user.directories = [ ".config/solaar" ];
  systemd.user.services.solaar = {
    description = "Solaar Logitech Device Manager";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # skipped in display-less sessions, where it cannot open a window
    unitConfig.ConditionEnvironment = [
      "|WAYLAND_DISPLAY"
      "|DISPLAY"
    ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.solaar} --window hide";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
