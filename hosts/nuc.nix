{ config, pkgs, lib, suites, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093";

in
{
  imports =
    suites.homeServer ++
    suites.virtualization ++
    suites.tpm ++
    suites.fw ++
    suites.campus;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  hardware.enableRedistributableFirmware = true;

  services.thermald.enable = true;
  services.scheduled-reboot.enable = true;

  networking.firewall.allowedTCPPorts = [
    3000 # temporary
  ];
  services.hydra = {
    enable = true;
    hydraURL = "hydra.li7g.com";
    notificationSender = "hydra@li7g.com";
    useSubstitutes = true;
    # use local db (default)
  };
  systemd.services.hydra-evaluator = {
    environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
  };
  environment.global-persistence.directories = [
    "/var/lib/hydra"
    "/var/lib/postgresql"
  ];
  nix.trustedUsers = [ "hydra" ];
  nix.distributedBuilds = true;
  users.users.hydra.openssh.authorizedKeys.keyFiles = [
    ../users/yinfeng/ssh/id_ed25519.pub
  ];
  nix.buildMachines = [
    {
      hostName = "localhost";
      sshKey = config.sops.secrets."yinfeng/id-ed25519".path;
      systems = [
        "x86_64-linux"
        "i686-linux"
      ];
      maxJobs = 4;
      speedFactor = 1;
    }
    {
      hostName = "eu.nixbuild.net";
      sshKey = config.sops.secrets."yinfeng/id-ed25519".path;
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
      ];
      supportedFeatures = [ "benchmark" "big-parallel" ];
      maxJobs = 100;
      speedFactor = 2;
    }
  ];
  sops.secrets."yinfeng/id-ed25519" = { };

  services.godns = {
    ipv4.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "nuc" ];
      }];
      ip_type = "IPv4";
      ip_interface = "enp88s0";
      # TODO if public ip working change to `ip_url`
      # ip_url = "https://myip.biturl.top";
    };
    ipv6.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "nuc" ];
      }];
      ip_type = "IPv6";
      ip_interface = "enp88s0";
    };
  };

  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=8G" "mode=755" ];
  };
  fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
  fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
  fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvolMain "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C9A4-3DE6";
      fsType = "vfat";
    };
  swapDevices = [{
    device = "/swap/swapfile";
  }];
}
