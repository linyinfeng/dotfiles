{ suites, ... }:

{
  imports =
    suites.multimedia ++
    suites.game ++
    suites.phone ++
    suites.printing;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.autoSuspend = false;
  hardware.video.hidpi.enable = true;
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };
}
