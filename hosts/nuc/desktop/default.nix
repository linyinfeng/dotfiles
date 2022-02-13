{ suites, ... }:

{
  imports =
    suites.multimedia ++
    suites.game ++
    suites.phone ++
    suites.printing;
  services.xserver.desktopManager.gnome.enable = true;
  hardware.video.hidpi.enable = true;
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };
}
