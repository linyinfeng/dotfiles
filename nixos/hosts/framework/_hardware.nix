# customized from https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/12th-gen-intel/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # early KMS
  hardware.intelgpu.loadInInitrd = true;

  # https://community.frame.work/t/tracking-hard-freezing-on-fedora-36-with-the-new-12th-gen-system/20675/391
  boot.kernelParams = [
    # Workaround iGPU hangs
    # https://discourse.nixos.org/t/intel-12th-gen-igpu-freezes/21768/4
    "i915.enable_psr=1"

    # Try
    "i915.enable_psr2_sel_fetch=1"
  ];

  # boot.blacklistedKernelModules = [
  #   # This enables the brightness and airplane mode keys to work
  #   # https://community.frame.work/t/12th-gen-not-sending-xf86monbrightnessup-down/20605/11
  #   "hid-sensor-hub"
  #   # This fixes controller crashes during sleep
  #   # https://community.frame.work/t/tracking-fn-key-stops-working-on-popos-after-a-while/21208/32
  #   "cros_ec_lpcs"
  # ];

  # Fix TRRS headphones missing a mic
  # https://community.frame.work/t/headset-microphone-on-linux/12387/3
  # boot.extraModprobeConfig = ''
  #   options snd-hda-intel model=dell-headset-multi
  # '';

  # Fix headphone noise when on powersave
  # https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
  # services.udev.extraRules = ''
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
  # '';

  # deeded for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = true;

  # deeded for window manager to manage display brightness
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
