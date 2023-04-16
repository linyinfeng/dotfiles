{
  pkgs,
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.hyprland.enable = true;
    environment.sessionVariables = {
      NIXOS_OZONE_WL = ""; # input method not working
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

    environment.systemPackages = with pkgs; [
      light
    ];
    security.sudo.extraRules = [
      {
        groups = ["users"];
        commands = [
          {
            command = "/run/current-system/sw/bin/light";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  }
  (lib.mkIf (!config.services.xserver.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [
      ".local/share/keyrings"
    ];
  })
]
