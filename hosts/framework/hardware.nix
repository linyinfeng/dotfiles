# customized from https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
{}:

{
  boot.kernelParams = [
    # For Power consumption
    # https://kvark.github.io/linux/framework/2021/10/17/framework-nixos.html
    # "mem_sleep_default=deep"
    # For Power consumption
    # https://community.frame.work/t/linux-battery-life-tuning/6665/156
    # "nvme.noacpi=1"
    # Workaround iGPU hangs
    # https://discourse.nixos.org/t/intel-12th-gen-igpu-freezes/21768/4
    # "i915.enable_psr=1"
  ];

  # This enables the brightness keys to work
  # https://community.frame.work/t/12th-gen-not-sending-xf86monbrightnessup-down/20605/11
  boot.blacklistedKernelModules = [ "hid-sensor-hub" ];

  # Fix TRRS headphones missing a mic
  # https://community.frame.work/t/headset-microphone-on-linux/12387/3
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=dell-headset-multi
  '';

  # Fix headphone noise when on powersave
  # https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
  # services.udev.extraRules = ''
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
  # '';

  # Mis-detected by nixos-generate-config
  # https://github.com/NixOS/nixpkgs/issues/171093
  # https://wiki.archlinux.org/title/Framework_Laptop#Changing_the_brightness_of_the_monitor_does_not_work
  hardware.acpilight.enable = lib.mkDefault true;
}
