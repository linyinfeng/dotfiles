{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";
  environment.global-persistence.directories = [
    "/var/lib/containers"
  ];
}
