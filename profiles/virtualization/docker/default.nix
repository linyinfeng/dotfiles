{ ... }:

{
  virtualisation.docker.enable = true;
  environment.global-persistence.directories = [
    "/var/lib/docker"
  ];
}
