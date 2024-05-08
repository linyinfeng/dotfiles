# https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/12th-gen-intel/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    # early KMS
    hardware.intelgpu.loadInInitrd = true;
  }

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
      name = "embedded"
      path = "/sys/class/backlight/intel_backlight"
      capturer = "wlroots"
    '';
    environment.global-persistence.user.directories = [ ".local/share/wluma" ];
  }

  {
    systemd.services = lib.mkIf (config.services.xserver.displayManager.gdm.enable) {
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
  }

  {
    boot.efiStub.splash =
      let
        # /sys/firmware/acpi/bgrt/image
        # size 900 x 119
        # /sys/firmware/acpi/bgrt/xoffset = 678
        # /sys/firmware/acpi/bgrt/yoffset = 515
        # screen size 2256 x 1504
        #
        # set extent to (2256 - 678 * 2) x (1504 - 515 * 2) to properly locate the image
        splash =
          pkgs.runCommand "logo-with-offset.bmp" { nativeBuildInputs = with pkgs; [ imagemagick ]; }
            ''
              convert -background black \
                -extent 900x474 \
                "${./logo.bmp}" $out
            '';
      in
      "${splash}";
  }

  {
    # logitech unifying
    services.udev.packages = with pkgs; [ logitech-udev-rules ];
    environment.systemPackages = with pkgs; [ solaar ];
  }
]
