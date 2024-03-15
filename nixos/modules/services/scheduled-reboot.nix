{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.scheduled-reboot;

  bootInfo = pkgs.writeScript "boot-info" ''
    readlink --canonicalize-existing "$1"/{initrd,kernel,kernel-modules}
    cat "$1"/kernel-params
  '';
in
{
  options.services.scheduled-reboot = {
    enable = lib.mkOption {
      type = with lib.types; bool;
      default = false;
      description = ''
        Wheather to enable scheduled-reboot service.
      '';
    };
    calendar = lib.mkOption {
      type = with lib.types; str;
      default = "04:00";
      description = ''
        Time to auto reboot.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.scheduled-reboot = {
      script = ''
        booted="$(${bootInfo} /run/booted-system)"
        boot="$(${bootInfo} /nix/var/nix/profiles/system)"

        echo "-- boot info for booted system"
        echo "$booted"
        echo "-- boot info for boot system"
        echo "$boot"

        if [ "$booted" = "$boot" ]; then
          echo "no need to reboot"
        else
          echo "schedule a reboot"
          /run/current-system/sw/bin/shutdown --reboot +1
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
    systemd.timers.scheduled-reboot = {
      timerConfig.OnCalendar = cfg.calendar;
      wantedBy = [ "timers.target" ];
    };
  };
}
