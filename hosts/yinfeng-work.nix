{ pkgs, lib, suites, hardware, ... }:

let

  btrfsSubvol = subvol: extraConfig: {
    device = "/dev/disk/by-uuid/3d22521e-0f64-4a64-ad29-40dcabda13a2";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "compress=zstd" ];
  } // extraConfig;

  godnsBasicConfig = {
    provider = "Cloudflare";
    login_token = import ../secrets/services/ddns/cloudflare-token.nix;
    domains = [
      {
        domain_name = "li7g.com ";
        sub_domains = [
          "work"
        ];
      }
    ];
    ip_interface = "enp4s0";
    interval = 300;
  };

  godnsService = { name, config }: {
    after = [ "network.target" ];
    serviceConfig = {
      Restart = "on-abort";
      ExecStart =
        let
          configFile = pkgs.writeText "${name}-config" (builtins.toJSON config);
        in
        "${pkgs.nur.repos.linyinfeng.godns}/bin/godns -c ${configFile}";
    };
    wantedBy = [ "multi-user.target" ];
  };

in
{
  imports =
    suites.workstation ++
    suites.gfw ++
    [
      hardware.common-pc
      hardware.common-cpu-intel
      hardware.common-pc-ssd
    ];

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.consoleMode = "auto";

  hardware.enableRedistributableFirmware = true;
  hardware.video.hidpi.enable = true;

  powerManagement.cpuFreqGovernor = "performance";

  systemd.services.godns-ipv4 = godnsService {
    name = "godns-ipv4";
    config = godnsBasicConfig // {
      ip_url = "";
      ip_type = "IPv4";
    };
  };
  systemd.services.godns-ipv6 = godnsService {
    name = "godns-ipv6";
    config = godnsBasicConfig // {
      ipv6_url = "";
      ip_type = "IPv6";
    };
  };

  environment.global-persistence.enable = true;
  environment.global-persistence.root = "/persist";

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=16G" "mode=755" ];
  };
  boot.initrd.luks.devices."crypt-root" = {
    device = "/dev/disk/by-uuid/29bb6dbb-7348-42a0-a9e9-6e7daa89d32e";
    allowDiscards = true;
  };
  fileSystems."/nix" = btrfsSubvol "@nix" { neededForBoot = true; };
  fileSystems."/persist" = btrfsSubvol "@persist" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvol "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/74C9-BFBC";
      fsType = "vfat";
    };
  fileSystems."/data" =
    {
      device = "/dev/disk/by-uuid/6c4a47ea-492e-4855-8157-180e74904b73";
      fsType = "ext4";
    };
  swapDevices = [{
    device = "/swap/swapfile";
  }];
}
