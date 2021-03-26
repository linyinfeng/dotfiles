{ pkgs, lib, suites, hardware, ... }:

let

  btrfsSubvol = subvol: extraConfig: {
    device = "/dev/disk/by-uuid/61c8be1d-7cb6-4a6d-bfa1-1fef8cadbe2d";
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
          "laptop"
        ];
      }
    ];
    ip_interface = "enp0s31f6";
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
    suites.mobileWorkstation ++
    suites.game ++
    suites.gfw ++
    [
      hardware.lenovo-thinkpad-t460s
      hardware.common-pc-ssd
    ];

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.video.hidpi.enable = true;

  powerManagement.cpuFreqGovernor = "powersave";

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

  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };
  boot.initrd.luks.devices."crypt-root".device =
    "/dev/disk/by-uuid/65aa660c-5b99-4663-a9cb-c69e18b6b6fd";
  fileSystems."/persist" = btrfsSubvol "@persist" { neededForBoot = true; };
  fileSystems."/nix" = btrfsSubvol "@nix" { neededForBoot = true; };
  fileSystems."/swap" = btrfsSubvol "@swap" { };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/8F31-70B2";
      fsType = "vfat";
    };
  fileSystems."/windows/c" =
    {
      device = "/dev/disk/by-uuid/ECB0C2DCB0C2AD00";
      fsType = "ntfs";
      options = [ "ro" "fmask=333" "dmask=222" ];
    };
  swapDevices =
    [{
      device = "/swap/swapfile";
    }];
}
