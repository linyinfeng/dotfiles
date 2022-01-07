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

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/3d22521e-0f64-4a64-ad29-40dcabda13a2";
  btrfsSubvolData = btrfsSubvol "/dev/disk/by-uuid/fc047db2-0ba9-445a-9b84-194af545fa23";

in
{
  imports =
    suites.desktopWorkstation ++
    suites.monitoring ++
    suites.tpm ++
    suites.fw ++
    suites.godns ++
    suites.ci-agent ++
    suites.samba ++
    suites.nixbuild ++
    suites.user-yinfeng;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "max";
    };
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  hardware.enableRedistributableFirmware = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;

  services.xserver.desktopManager.gnome.enable = true;

  virtualisation.kvmgt = {
    enable = true;
    device = "0000:00:02.0";
    vgpus = {
      i915-GVTg_V5_4 = {
        uuid = [
          "15feffce-745b-4cb6-9f48-075af14cdb6f"
        ];
      };
    };
  };
  networking.campus-network = {
    enable = true;
    auto-login.enable = true;
  };
  services.portal = {
    host = "portal.li7g.com";
    client.enable = true;
  };
  services.godns = {
    ipv4.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "xps8930" ];
      }];
      ip_type = "IPv4";
      ip_interface = "enp4s0";
    };
    ipv6.settings = {
      domains = [{
        domain_name = "li7g.com";
        sub_domains = [ "xps8930" ];
      }];
      ip_type = "IPv6";
      ip_interface = "enp4s0";
    };
  };
  services.hercules-ci-agent.settings = {
    concurrentTasks = 2;
  };
  services.github-runner = {
    enable = true;
    name = "xps8930";
    replace = true;
    extraLabels = [ "nixos" ];
    tokenFile = config.sops.secrets."xps8930/github-runner".path;
    url = "https://github.com/linyinfeng/dotfiles";
    extraPackages = with pkgs; [ openssh ];
  };
  sops.secrets."xps8930/github-runner" = { };
  environment.global-persistence.directories = [ "/var/lib/private/github-runner" ];
  systemd.services.github-runner.environment = lib.mkIf (config.networking.fw-proxy.enable)
    config.networking.fw-proxy.environment;
  nix.allowedUsers = [ "github-runner" ];
  nix.gc.options =
    let
      freeSpaceGB = 30;
    in
    # https://github.com/hercules-ci/hercules-ci-agent/blob/master/internal/nix/gc.nix
    ''--max-freed "$((${toString freeSpaceGB} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))" --delete-older-than 14d'';

  services.notify-failure.services = [
    "github-runner"
  ];

  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "uas" "sd_mod" "sr_mod" ];
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=16G" "mode=755" ];
  };
  boot.initrd.luks.devices."crypt-root" = {
    device = "/dev/disk/by-uuid/29bb6dbb-7348-42a0-a9e9-6e7daa89d32e";
    allowDiscards = true;
  };
  boot.initrd.luks.devices."crypt-mobile" = {
    device = "/dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c";
  };
  boot.initrd.luks.devices."crypt-data" = {
    device = "/dev/disk/by-uuid/0f9a546e-f458-46d9-88a4-4f6b157579ea";
  };
  fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
  fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
  fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvolMain "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/74C9-BFBC";
      fsType = "vfat";
    };
  fileSystems."/media/data" = btrfsSubvolData "@data" { };
  swapDevices = [{
    device = "/swap/swapfile";
  }];
}
