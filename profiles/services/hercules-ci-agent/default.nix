{ lib, ... }:

# TODO: currently broken
lib.mkIf false
{
  services.hercules-ci-agent.enable = true;

  environment.global-persistence.directories = [
    "/var/lib/hercules-ci-agent"
  ];
}
