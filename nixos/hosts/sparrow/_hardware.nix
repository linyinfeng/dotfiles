{ pkgs, ... }:
{
  # https://github.com/velvet-os/velvet-os.github.io/blob/main/chromebooks/systems/kukui/krane.md

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Google Chromebook Krane Trackpad]
    MatchUdevType=touchpad
    MatchName=Google Inc. Hammer
    MatchBus=usb
    MatchDeviceTree=*krane*
    ModelChromebook=1
    AttrPressureRange=20:10

    [Google Chromebook Krane Stylus Digitizer]
    MatchUdevType=tablet
    MatchDeviceTree=*krane*
    MatchBus=i2c
    ModelChromebook=1
    AttrPressureRange=1100:1000
  '';
  environment.etc."libwacom/google-krane.tablet".text = ''
    [Device]
    Name=hid-over-i2c 27C6:0E30 Stylus
    ModelName=
    DeviceMatch=i2c:27c6:0e30
    Class=ISDV4
    Width=5.35433
    Height=8.54331
    IntegratedIn=Display;System
    Styli=@generic-no-eraser

    [Features]
    Stylus=true
    Touch=false
  '';

  systemd.package = pkgs.systemd.override {
    withEfi = false;
  };

  # when using usb drive as root
  # after switching root, loading this module causes root filesystem disconnection
  boot.blacklistedKernelModules = [ "onboard_usb_dev" ];
  boot.initrd.systemd.tpm2.enable = false;

  home-manager.users.yinfeng.services.kanshi.settings =
    let
      embedded = "DSI-1";
    in
    [
      {
        output = {
          criteria = embedded;
          scale = 1.75;
          transform = "90";
        };
      }
      {
        profile = {
          name = "mobile";
          outputs = [
            { criteria = embedded; }
          ];
        };
      }
    ];

  # needed for window manager to manage display brightness
  environment.systemPackages = with pkgs; [ wluma ];
  environment.etc."xdg/wluma/config.toml".text = ''
    [als.iio]
    path = "/sys/bus/iio/devices"
    thresholds = { 0 = "night", 20 = "dark", 80 = "dim", 250 = "normal", 500 = "bright", 800 = "outdoors" }

    [[output.backlight]]
    name = "DSI-1"
    path = "/sys/class/backlight/backlight_lcd0"
    capturer = "wayland"
  '';
  environment.global-persistence.user.directories = [ ".local/share/wluma" ];
}
