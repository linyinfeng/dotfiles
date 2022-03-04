{ config, pkgs, suites, ... }:

{
  imports =
    suites.server ++
    suites.networkManager ++
    suites.samba ++
    suites.transmission ++
    suites.autoUpgrade ++
    suites.behindFw ++
    [
      ./networking/wireguard
      ./networking/auto-login
      ./services/shadowsocks
      ./users/root
      ./users/matrixlt.nix
    ];

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/disk/by-id/ata-Phison_SATA_SSD_DF5B079A1E3700464150";
  };

  services.logind.lidSwitch = "ignore";
  security.sudo.wheelNeedsPassword = false;
  sops.secrets."transmission/credentials".sopsFile = config.sops.secretsDir + /g150t-s.yaml;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  # hardware configurations

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.enableRedistributableFirmware = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/e5521aab-0360-4d3d-8a6a-dc78c2693d00";
      fsType = "ext4";
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = "powersave";
}
