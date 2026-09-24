{ ... }:
{
  world.profiles = {
    graphical = {
      activate-linux.enable = true;
      fonts.enable = true;
      gnome.enable = true;
      kde.enable = true;
      niri.enable = true;
    };
    i18n.input-method.enable = true;
    services = {
      gnome-keyring.enable = true;
      pipewire.enable = true;
    };
  };
}
