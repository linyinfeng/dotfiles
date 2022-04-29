{ pkgs, config, suites, profiles, lib, modulesPath, ... }:
let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/c0e72722-18c2-4250-9034-676287478998";
in
{
  imports =
    suites.server ++
    (with profiles; [
      programs.telegram-send
      services.acme
      services.notify-failure
    ]) ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      boot.loader.grub = {
        enable = true;
        version = 2;
        device = "/dev/vda";
      };
      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
      boot.kernelModules = [ "kvm-amd" ];

      boot.tmpOnTmpfs = true;
      services.fstrim.enable = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      environment.systemPackages = with pkgs; [
        tmux
      ];

      fileSystems."/" =
        {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "defaults" "size=2G" "mode=755" ];
        };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" =
        {
          device = "/dev/disk/by-uuid/f8d738d7-a2be-448f-a521-2b2a408d2572";
          fsType = "ext4";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    # nginx
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;

        virtualHosts = {
          "nexusbytes.li7g.com" = {
            default = true;
            forceSSL = true;
            useACMEHost = "main";
            serverAliases = [
              "nexusbytes.ts.li7g.com"
            ];
          };
        };
      };
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    }

    # acme
    {
      security.acme.certs."main" = {
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.templates.acme-credentials.path;
        domain = "nexusbytes.li7g.com";
        extraDomainNames = [
          "nexusbytes.ts.li7g.com"
          "smtp.li7g.com"
          "smtp.ts.li7g.com"
        ];
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
    }

    # postgresql
    {
      services.postgresql.enable = true;
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
      # TODO ipv6 not working
      # environment.etc."systemd/network/50-ens3-ipv6.network".source = config.sops.templates."ens3-ipv6.network".path;
      # sops.secrets."ipv6-address".sopsFile = config.sops.secretsDir + /nexusbytes.yaml;
      # sops.templates."ens3-ipv6.network".content = ''
      #   [Match]
      #   Name=ens3

      #   [Network]
      #   Address=${config.sops.placeholder."ipv6-address"}
      # '';
    }
  ];
}
