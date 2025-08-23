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
    environment.systemPackages = with pkgs; [
      swaylock
      swayosd
    ];
    systemd.packages = with pkgs; [ swayosd ];
    systemd.services."swayosd-libinput-backend" = {
      wantedBy = [ "graphical.target" ];
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
    systemd.user.services.niri-flake-polkit = {
      description = "PolicyKit Authentication Agent provided by niri-flake";
      wantedBy = [ "niri.service" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
    programs.wshowkeys.enable = true;
  }
  (lib.mkIf (!config.services.desktopManager.gnome.enable) {
    services.gnome.gnome-keyring.enable = true;
    environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
  })
]
