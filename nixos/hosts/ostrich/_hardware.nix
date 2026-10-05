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
      # Ada Lovelace is supported by the open kernel modules
      open = true;
      # required by the display manager and every Wayland compositor
      modesetting.enable = true;
      nvidiaSettings = true;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.full
      vulkan-tools
      libva-utils
    ];
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
