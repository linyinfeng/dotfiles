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
    systemd.services.podman-auto-update.environment =
      lib.mkIf (config.networking.fw-proxy.enable)
        config.networking.fw-proxy.environment;
  }
  {
    environment.systemPackages = with pkgs; [
      distrobox
    ];
  }
]
