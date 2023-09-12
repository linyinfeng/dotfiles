# customized from https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
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
  # boot.blacklistedKernelModules = [ "hid-sensor-hub" ];

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

  # Mis-detected by nixos-generate-config
  # https://github.com/NixOS/nixpkgs/issues/171093
  # https://wiki.archlinux.org/title/Framework_Laptop#Changing_the_brightness_of_the_monitor_does_not_work
  # hardware.acpilight.enable = lib.mkDefault true;

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = true;
  environment.systemPackages = with pkgs; [
    wluma
  ];
  environment.etc."xdg/wluma/config.toml".text = ''
    [als.iio]
    path = "/sys/bus/iio/devices"
    thresholds = { 0 = "night", 20 = "dark", 80 = "dim", 250 = "normal", 500 = "bright", 800 = "outdoors" }

    [[output.backlight]]
    name = "embedded"
    path = "/sys/class/backlight/intel_backlight"
    capturer = "wlroots"
  '';
  environment.global-persistence.user.directories = [
    ".local/share/wluma"
  ];
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
      before = ["display-manager.service"];
      wantedBy = ["display-manager.service"];
    };
  };

  boot = {
    # https://github.com/intel/mainline-tracking/tags
    kernelPackages = let
      linux_intel_fn = {
        fetchFromGitHub,
        buildLinux,
        lib,
        ...
      } @ args:
        buildLinux (args
          // rec {
            version = "6.4";
            modDirVersion = lib.versions.pad 3 version;
            extraMeta.branch = lib.versions.majorMinor version;
            src = fetchFromGitHub {
              owner = "intel";
              repo = "mainline-tracking";
              rev = "mainline-tracking-v6.4-linux-230816T023734Z";
              sha256 = "sha256-8gHrgO+nrItJe2ulO/7C4ZQvjjwr+9NJxCOQOln5a0Y=";
            };
          }
          // (args.argsOverride or {}));
      linux_intel = pkgs.callPackage linux_intel_fn {
        kernelPatches = pkgs.linuxPackages_6_4.kernel.kernelPatches;
      };
    in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_intel);
    kernelPatches = [
      # TODO wait for https://bugzilla.kernel.org/show_bug.cgi?id=217631
      {
        name =   "framework-12th-tpm-tis-workaround";
        # https://lore.kernel.org/all/20230710211635.4735-1-mail@eworm.de/
        patch = ../../../patches/framework-12th-tpm-tis-workaround.patch;
      }
    ];
  };
  # out-of-tree module "kvmfr" required
  # # because kernel needs to be recompiled
  # # enable lockdown by the way
  # boot.kernelLockdown = false;
}
