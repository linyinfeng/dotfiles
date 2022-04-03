{ config, pkgs, suites, profiles, lib, modulesPath, ... }:

let

  btrfsSubvol = device: subvol: extraConfig: lib.mkMerge [
    {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=${subvol}" "compress=zstd" ];
    }
    extraConfig
  ];
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in
{
  imports =
    suites.server ++
    (with profiles; [
      networking.behind-fw
      networking.wireguard-home
      services.acme
    ]) ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
      ./steam
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

      boot.tmpOnTmpfs = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

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
          device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
          fsType = "ext4";
        };
      swapDevices =
        [{
          device = "/swap/swapfile";
        }];
    }

    # acme
    {
      security.acme.certs = {
        "tencent.li7g.com" = {
          dnsProvider = "cloudflare";
          credentialsFile = config.sops.templates.acme-credentials.path;
          extraDomainNames = [
            "tencent.ts.li7g.com"
            "shanghai.derp.li7g.com"
          ];
        };
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
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
          "tencent.li7g.com" = {
            default = true;
            onlySSL = true;
            useACMEHost = "tencent.li7g.com";
            serverAliases = [
              "tencent.ts.li7g.com"
            ];
          };
        };
      };
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
      # only port 443
      networking.firewall.allowedTCPPorts = [ 443 ];
    }

    # zerotier moon
    {
      # add new script
      systemd.services.zerotierone-presetup = {
        script = lib.mkAfter ''
          cd /var/lib/zerotier-one
          mkdir -p moons.d
          cd moons.d
          zerotier-idtool genmoon "${config.sops.secrets."zerotier/moon.json".path}"
        '';
        path = [
          config.services.zerotierone.package
        ];
      };
      sops.secrets."zerotier/moon.json".sopsFile = config.sops.secretsDir + /tencent.yaml;
    }

    # tailscale derp server
    (
      let
        derperPort = 8443;
      in
      {
        systemd.services.derper = {
          script = ''
            ${pkgs.tailscale-derp}/bin/derper \
              -a ":${toString derperPort}" \
              -http-port "-1" \
              --hostname="shanghai.derp.li7g.com" \
              -certdir "$CREDENTIALS_DIRECTORY" \
              -certmode manual \
              -verify-clients
          '';
          serviceConfig = {
            LoadCredential = [
              "shanghai.derp.li7g.com.crt:${config.security.acme.certs."tencent.li7g.com".directory}/full.pem"
              "shanghai.derp.li7g.com.key:${config.security.acme.certs."tencent.li7g.com".directory}/key.pem"
            ];
          };
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.service" ];
        };
        networking.firewall.allowedTCPPorts = [
          derperPort
        ];
        networking.firewall.allowedUDPPorts = [
          3478 # STUN port
        ];
      }
    )

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens5.useDHCP = true;
      };
    }
  ];
}
