{
  suites,
  profiles,
  ...
}: {
  imports =
    suites.multimedia
    ++ suites.games
    ++ (with profiles; [
      services.kde-connect
      services.printing
    ]);
  services.xserver.desktopManager.gnome.enable = true;
  hardware.video.hidpi.enable = true;
  programs.steam.hidpi = {
    enable = true;
    scale = "2";
  };
}
