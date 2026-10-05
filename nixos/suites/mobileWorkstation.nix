{ ... }:
{
  world = {
    profiles = {
      graphical.graphical-powersave-target.enable = true;
      graphical.noctalia.enable = true;
      graphical.umbriel.enable = true;
      networking = {
        behind-fw.enable = true;
        fw-proxy.enable = true;
      };
    };
    suites.workstation.enable = true;
  };
}
