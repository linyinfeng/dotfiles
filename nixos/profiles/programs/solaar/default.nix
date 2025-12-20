{ pkgs, lib, ... }:
{
  services.udev.packages = with pkgs; [ logitech-udev-rules ];
  environment.systemPackages = with pkgs; [ solaar ];
  environment.global-persistence.user.directories = [ ".config/solaar" ];
  systemd.user.services.solaar = {
    description = "Solaar Logitech Device Manager";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.solaar} --window hide";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
