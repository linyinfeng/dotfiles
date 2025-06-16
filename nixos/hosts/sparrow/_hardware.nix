{ pkgs, lib, ... }:
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

  boot.kernelPatches = [
    {
      name = "kukui-extra-options";
      patch = null;
      extraStructuredConfig = {
        # required by envfs
        EROFS_FS = lib.kernel.yes;
      };
    }
  ];

  boot.initrd.systemd.tpm2.enable = false;
}
