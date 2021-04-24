{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  environment.global-persistence.directories = [
    "/var/lib/docker"
  ];
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
