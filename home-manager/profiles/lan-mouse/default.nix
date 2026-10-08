{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      programs.lan-mouse.enable = true;

      # Peers pin the daemon's TLS identity from here, so it has to survive an
      # impermanent boot.
      home.global-persistence.directories = [ ".config/lan-mouse" ];
    }

    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Upstream wants this unit from the hyprland and sway session targets,
      # which umbriel does not provide.
      systemd.user.services.lan-mouse = {
        Unit = {
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
      };
    })
  ];
}
