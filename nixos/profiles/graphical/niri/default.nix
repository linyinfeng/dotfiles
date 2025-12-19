{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.niri.enable = true;
  }
  (lib.mkIf (!config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
  })
]
