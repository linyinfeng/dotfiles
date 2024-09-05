{ ... }:
{
  services.fprintd.enable = true;
  systemd.services.fprintd = {
    unitConfig = {
      ConditionPathExists = [ "!/run/fprintd-blocker" ];
    };
  };
  systemd.services.fprintd-blocker = {
    script = ''
      touch /run/fprintd-blocker
      systemctl stop fprintd.service
    '';
    preStop = ''
      rm /run/fprintd-blocker
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") === "fprintd-blocker.service" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
