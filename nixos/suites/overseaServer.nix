{ ... }:
{
  world = {
    profiles.services = {
      acme.enable = true;
      bind.enable = true;
      nginx.enable = true;
    };
    suites.server.enable = true;
  };
}
