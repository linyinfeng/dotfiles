{ suites, profiles, ... }:
{
  imports =
    suites.multimedia
    ++ (with profiles; [
      services.kde-connect
      services.printing
    ]);
  services.desktopManager.gnome.enable = true;
}
