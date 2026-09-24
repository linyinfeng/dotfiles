{ ... }:
{
  world = {
    profiles = {
      networking.bbr.enable = true;
      system.types.server.enable = true;
    };
    suites = {
      base.enable = true;
      network.enable = true;
    };
  };
}
