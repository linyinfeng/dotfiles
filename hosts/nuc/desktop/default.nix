{ suites, ... }:

{
  imports =
    suites.multimedia ++
    suites.game ++
    suites.phone ++
    suites.printing;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "yinfeng";
  };
}
