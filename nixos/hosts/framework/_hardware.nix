# customized from https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/12th-gen-intel/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # boot.kernelParams = [
  #   # For Power consumption
  #   # https://kvark.github.io/linux/framework/2021/10/17/framework-nixos.html
  #   "mem_sleep_default=deep"
  #   # Workaround iGPU hangs
  #   # https://discourse.nixos.org/t/intel-12th-gen-igpu-freezes/21768/4
  #   "i915.enable_psr=1"
  # ];

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

  boot = {
    # https://github.com/intel/linux-intel-lts/tags
    # https://github.com/intel/mainline-tracking/tags
    kernelPackages =
      let
        kind = "lts";
        repo =
          if kind == "lts" then
            "linux-intel-lts"
          else if kind == "mainline-tracking" then
            "mainline-tracking"
          else
            throw "invalid intel kernel kind \"${kind}\"";
        version = "6.6.14";
        versionIntel = "240205T072842Z";
        hash = "sha256-UGJ/y3fr7q2ThORkEGzDKNZ15XL/YDDJ84NVYSuGrZo=";
        major = lib.versions.major version;
        minor = lib.versions.minor version;
        linux_intel_fn =
          {
            fetchFromGitHub,
            buildLinux,
            ccacheStdenv,
            lib,
            ...
          }@args:
          buildLinux (
            args
            // {
              # build with ccacheStdenv
              stdenv = ccacheStdenv;
              inherit version;
              modDirVersion = lib.versions.pad 3 version;
              extraMeta.branch = lib.versions.majorMinor version;
              src = fetchFromGitHub {
                owner = "intel";
                inherit repo;
                rev = "${kind}-v${version}-linux-${versionIntel}";
                inherit hash;
              };
            }
            // (args.argsOverride or { })
          );
        linux_intel = pkgs.callPackage linux_intel_fn {
          kernelPatches = lib.filter (
            p: !(lib.elem p.name [ ])
          ) pkgs."linuxPackages_${major}_${minor}".kernel.kernelPatches;
        };
      in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_intel);
    kernelPatches = [
      # currently nothing
    ];
  };
  # because kernel needs to be recompiled
  # enable module signing and lockdown by the way
  boot.kernelModuleSigning.enable = true;
  boot.kernelLockdown = true;
}
