{ config, pkgs, lib, ... }:

let
  podman = "${pkgs.podman}/bin/podman";
in
lib.mkMerge [
  {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
    virtualisation.oci-containers.backend = "podman";
    systemd.services.podman-auto-update = {
      description = "Podman auto-update service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${podman} auto-update";
        ExecStartPost = "${podman} image prune -f";
      };
      wantedBy = [ "multi-user.target" "default.target" ];
    };
    systemd.timers.podman-auto-update = {
      description = "Podman auto-update timer";
      timerConfig = {
        OnCalendar = "daily";
        RamdomizedDelaySec = 900;
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    environment.global-persistence.directories = [
      "/var/lib/containers"
    ];
  }
  {
    systemd.services = lib.mapAttrs'
      (name: _: lib.nameValuePair "podman-${name}" {
        environment = {
          PODMAN_SYSTEMD_UNIT = "%n";
        };
      })
      config.virtualisation.oci-containers.containers;
  }
]
