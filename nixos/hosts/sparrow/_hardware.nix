{ pkgs, lib, ... }:
lib.mkMerge [
  # kernel
  {
    hardware.enableAllFirmware = true;
    hardware.deviceTree.filter = "mt8183-kukui-krane*.dtb";

    # when using usb drive as root
    # after switching root, loading this module causes root filesystem disconnection
    boot.blacklistedKernelModules = [ "onboard_usb_dev" ];
  }

  # systemd
  {
    systemd.package = pkgs.systemd.override {
      withEfi = false;
    };
    boot.initrd.systemd.tpm2.enable = false;
  }

  # inputs
  {
    # https://wiki.postmarketos.org/wiki/Lenovo_IdeaPad_Duet_Chromebook_(google-krane)
    environment.etc."libinput/local-overrides.quirks".text = ''
      [Touchpad pressure override]
      MatchUdevType=touchpad
      MatchName=Google Inc. Hammer
      AttrPressureRange=20:10

      [Google Chromebook Krane Stylus Digitizer]
      MatchUdevType=tablet
      MatchDeviceTree=*krane*
      MatchBus=i2c
      ModelChromebook=1
      AttrPressureRange=1100:1000
    '';
  }

  # display
  {
    home-manager.users.yinfeng.services.kanshi.settings =
      let
        embedded = "DSI-1";
      in
      [
        {
          output = {
            criteria = embedded;
            scale = 1.75;
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

  # hardware video acceleration
  {
    hardware.graphics.extraPackages = [
      pkgs.linyinfeng.libva-v4l2
    ];
    environment.systemPackages = with pkgs; [ libva-utils ];
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "v4l2";
      GST_VAAPI_ALL_DRIVERS = "1";
    };
  }

  # touchscrren
  {
    services.udev.extraRules = ''
      SUBSYSTEM=="input", ENV{ID_INPUT_TOUCHSCREEN}=="1", ENV{ID_PATH}=="platform-11007000.i2c", SYMLINK+="input/touchscreen"
    '';
  }
]
