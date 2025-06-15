{ lib, osConfig, ... }:
lib.mkIf osConfig.hardware.opentabletdriver.enable {
  systemd.user.services.otd-daemon = {
    Unit = {
      Description = "OpenTabletDriver daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${osConfig.hardware.opentabletdriver.package}/bin/otd-daemon";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
