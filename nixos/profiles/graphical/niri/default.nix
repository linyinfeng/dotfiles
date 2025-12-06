{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.niri.enable = true;
    security.soteria.enable = true;
    systemd.user.services.polkit-soteria.wantedBy = [ "niri.service" ];
  }
  (lib.mkIf (!config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
  })
]
