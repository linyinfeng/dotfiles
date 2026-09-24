{ ... }:
{
  world = {
    profiles.services = {
      kde-connect.enable = true;
      printing.enable = true;
    };
    suites.multimedia.enable = true;
  };
  services.desktopManager.gnome.enable = true;
}
