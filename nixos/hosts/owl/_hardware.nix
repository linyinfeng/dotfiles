# https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/12th-gen-intel/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    # needed for desktop environments to detect/manage display brightness
    hardware.sensor.iio.enable = true;

    # needed for window manager to manage display brightness
    environment.systemPackages = with pkgs; [ wluma ];
    environment.etc."xdg/wluma/config.toml".text = ''
      [als.iio]
      path = "/sys/bus/iio/devices"
      thresholds = { 0 = "night", 20 = "dark", 80 = "dim", 250 = "normal", 500 = "bright", 800 = "outdoors" }

      [[output.backlight]]
      name = "eDP-1"
      path = "/sys/class/backlight/amdgpu_bl1"
      capturer = "wlroots"
    '';
    environment.global-persistence.user.directories = [ ".local/share/wluma" ];
  }

  {
    systemd.services = lib.mkIf config.services.xserver.displayManager.gdm.enable {
      gdm-prepare = {
        script = ''
          mkdir -p .config
          ln -sf ${./monitors.xml} .config/monitors.xml
        '';
        serviceConfig = {
          User = config.users.users.gdm.name;
          Group = config.users.users.gdm.name;
          StateDirectory = "gdm";
          WorkingDirectory = "/var/lib/gdm";
        };
        before = [ "display-manager.service" ];
        wantedBy = [ "display-manager.service" ];
      };
    };
    systemd.tmpfiles.settings."80-gdm-monitors" = {
      "${config.users.users.gdm.home}/.config/monitors.xml" = {
        "L+" = {
          argument = "${./monitors.xml}";
        };
      };
    };

    home-manager.users.yinfeng.services.kanshi.settings =
      let
        embedded = "eDP-1";
        labMonitor = "Lenovo Group Limited P27h-20 U5HCT52K";
        dormMonitor = "A/Vaux Electronics AVT GC551G2 Unknown"; # capture card
      in
      [
        {
          output = {
            criteria = embedded;
            scale = 2.0;
          };
        }
        {
          output = {
            criteria = labMonitor;
            scale = 1.0;
          };
        }
        {
          output = {
            criteria = dormMonitor;
            scale = 1.25;
          };
        }
        {
          profile = {
            name = "undocked";
            outputs = [
              { criteria = embedded; }
            ];
          };
        }
        {
          profile = {
            name = "docked-lab";
            outputs = [
              {
                criteria = labMonitor;
                position = "0,0";
              }
              {
                criteria = embedded;
                position = "2560,580";
              }
            ];
          };
        }
        {
          profile = {
            name = "docked-lab-single";
            outputs = [
              {
                criteria = labMonitor;
                position = "0,0";
              }
            ];
          };
        }
        {
          profile = {
            name = "docked-dorm";
            outputs = [
              {
                criteria = embedded;
                position = "0,192";
              }
              {
                criteria = dormMonitor;
                position = "1536,0";
              }
            ];
          };
        }
      ];
  }
]
