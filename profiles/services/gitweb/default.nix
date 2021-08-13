{ config, ... }:

{
  services.nginx.gitweb.enable = true;

  environment.global-persistence.directories = [
    config.services.gitweb.projectroot
  ];
}
