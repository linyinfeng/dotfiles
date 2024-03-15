{ suites, profiles, ... }:
{
  imports =
    suites.multimedia
    ++ (with profiles; [
      services.kde-connect
      services.printing
    ]);
  services.xserver.desktopManager.gnome.enable = true;
}
