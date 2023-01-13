{ config, pkgs, lib, ... }:

let
  podman = "${pkgs.podman}/bin/podman";
in
lib.mkMerge [
  {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    virtualisation.oci-containers.backend = "podman";
    systemd.services.podman-auto-update = {
      serviceConfig = {
        ExecStart = [
          "" # override original
          "${podman} auto-update"
        ];
        ExecStartPost = [
          "" # override original
          "${podman} image prune -f"
        ];
      };
      environment =
        lib.mkIf (config.networking.fw-proxy.enable)
          config.networking.fw-proxy.environment;
    };
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
  {
    environment.systemPackages = with pkgs; [
      distrobox
    ];
  }
]
