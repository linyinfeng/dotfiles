{ ... }:
{
  world.profiles = {
    graphical = {
      activate-linux.enable = true;
      fonts.enable = true;
      noctalia.enable = true;
      umbriel.enable = true;
    };
    i18n.input-method.enable = true;
    services = {
      gnome-keyring.enable = true;
      pipewire.enable = true;
    };
  };
}
