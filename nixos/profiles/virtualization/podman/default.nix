{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      autoPrune.enable = true;
      defaultNetwork.settings = {
        network_interface = "podman0";
        dns_enabled = true;
      };
    };
    virtualisation.oci-containers.backend = "podman";
    systemd.services.podman-auto-update.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  }
  {
    environment.systemPackages = with pkgs; [
      podman-compose
      distrobox
    ];
    environment.global-persistence.user.directories = [
      ".local/share/containers"
    ];
  }
  {
    virtualisation.docker.enable = false;
  }
]
