{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  # The Ryzen 5 7500F has no integrated graphics, so the RTX 4060 is the only
  # GPU and drives every output.
  {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      branch = "latest";
      modesetting.enable = true;
      nvidiaSettings = true;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.full
      vulkan-tools
      libva-utils
    ];

    # Ada is the only GPU here, while the default build compiles kernels for
    # nine architectures
    assertions = [
      {
        assertion = lib.versionOlder pkgs.llama-cpp.version "0.7.0";
        message = "nixpkgs llama-cpp is now ${pkgs.llama-cpp.version}; drop the 0.7.0 override in nixos/hosts/ostrich/_hardware.nix";
      }
    ];

    services.llama-cpp.package = pkgs.llama-cpp-cuda.overrideAttrs (old: {
      version = "0.7.0";
      src = pkgs.fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        tag = "v0.7.0";
        hash = "sha256-pEDYgI3AMTU+cekvRX7NNt5wddznydQSNuerswvEpsA=";
      };
      patches = [ ];
      npmDepsHash = "sha256-hqYzdp1FwPhYkBP278fQXgY9NCKB6Q3P6Gko7BfP0m0=";
      disabledTests = old.disabledTests ++ [ "test-llama-context-model" ];
      cmakeFlags =
        lib.filter (flag: !(lib.hasPrefix "-DCMAKE_CUDA_ARCHITECTURES" flag)) old.cmakeFlags
        ++ [ "-DCMAKE_CUDA_ARCHITECTURES=89" ];
    });
  }

  {
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "ahci"
    ];
    boot.extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
  }

  # The IT8689E's fan and PWM registers share the I/O range 0xA45-0xA46 with
  # the ACPI \GSA1.SIO1 OpRegion, so the it87 probe aborts with -EBUSY unless
  # the resource check is relaxed; this is what makes the three fan tachometers
  # readable from `sensors` and telegraf.
  {
    boot.kernelModules = [ "it87" ];
    boot.extraModprobeConfig = ''
      options it87 ignore_resource_conflict=1
    '';
  }

  # powertop tweaks
  (
    let
      usbIds = {
        "ATK Mouse 8K Dongle" = "373b:101b";
        "Milsky 68EC-S Keyboard" = "0483:5132";
      };
      parseUsbId =
        _name: id:
        let
          parsed = lib.splitString ":" id;
        in
        {
          vendor = lib.elemAt parsed 0;
          product = lib.elemAt parsed 1;
        };
      parsed = lib.mapAttrs parseUsbId usbIds;
    in
    {
      services.udev.extraRules = lib.concatMapAttrsStringSep "\n" (name: id: ''
        # Disable auto suspend for ${name}
        ACTION=="bind", SUBSYSTEM=="usb", ATTR{idVendor}=="${id.vendor}", ATTR{idProduct}=="${id.product}", TEST=="power/control", ATTR{power/control}="on"
      '') parsed;
      powerManagement.powertop = {
        enable = true;
        postStart = lib.concatMapAttrsStringSep "\n" (_name: id: ''
          ${lib.getExe' config.systemd.package "udevadm"} trigger -c bind -s usb -a idVendor=${id.vendor} -a idProduct=${id.product}
        '') parsed;
      };
    }
  )
]
