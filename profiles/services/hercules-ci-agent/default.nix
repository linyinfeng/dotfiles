{
  # TODO: currently broken
  # services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.enable = false;

  environment.global-persistence.directories = [
    "/var/lib/hercules-ci-agent"
  ];
}
