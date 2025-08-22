{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
    systemd.user.services.niri-flake-polkit.serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
    };
    programs.wshowkeys.enable = true;
  }
  (lib.mkIf (!config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
  })
]
