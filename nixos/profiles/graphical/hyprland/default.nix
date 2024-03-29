{
  pkgs,
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    environment.sessionVariables = {
      # override the setting in hyprland module
      # priority of mkDefault is 1000
      # default priority is 100
      NIXOS_OZONE_WL = lib.mkOverride 990 "";
    };

    systemd.user.services.xdg-desktop-portal-hyprland = {
      unitConfig = {
        ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
      };
    };
    systemd.user.services.xdg-desktop-portal-gnome = {
      unitConfig = {
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=GNOME";
      };
    };

    security.pam.services.swaylock.text = ''
      account required pam_unix.so

      # check passwork before fprintd
      auth sufficient pam_unix.so try_first_pass likeauth
      auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth required pam_deny.so

      password sufficient pam_unix.so nullok yescrypt

      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
    '';
  }

  (lib.mkIf (!config.services.xserver.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
  })
]
