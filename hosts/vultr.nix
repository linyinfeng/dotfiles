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
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";

  portalHost = "portal.li7g.com";
  dotTarPort = 8001;
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

      boot.tmpOnTmpfs = true;
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
        "vultr.li7g.com" = {
          dnsProvider = "cloudflare";
          credentialsFile = config.sops.templates.acme-credentials.path;
          extraDomainNames = [
            "li7g.com"
            "portal.li7g.com"
            "tar.li7g.com"
            "nuc-proxy.li7g.com"
          ];
        };
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
    }

    # nginx
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    }

    # matrix well-known
    {
      services.nginx.virtualHosts."li7g.com" = {
        forceSSL = true;
        useACMEHost = "vultr.li7g.com";
        locations."/.well-known/matrix/server".return = ''
          200 '{ "m.server": "matrix.li7g.com:8443" }'
        '';
        locations."/.well-known/matrix/client" = {
          return = ''
            200 '{ "m.homeserver": { "base_url": "https://matrix.li7g.com:8443" } }'
          '';
          extraConfig = ''
            add_header Access-Control-Allow-Origin '*';
          '';
        };
      };
    }

    # portal
    {
      services.nginx.virtualHosts.${config.services.portal.host} = {
        forceSSL = true;
        useACMEHost = "vultr.li7g.com";
        locations."/" = {
          root = pkgs.element-web-li7g-com;
        };
      };
      services.portal = {
        host = portalHost;
        server.enable = true;
      };
    }

    # dot-tar
    {
      services.nginx.virtualHosts."tar.li7g.com" = {
        forceSSL = true;
        useACMEHost = "vultr.li7g.com";
        locations."/" = {
          proxyPass = "http://localhost:${toString dotTarPort}";
        };
      };
      services.dot-tar = {
        enable = true;
        config = {
          release = {
            port = dotTarPort;
            authority_allow_list = [
              "github.com"
            ];
          };
        };
      };

      services.notify-failure.services = [
        "dot-tar"
      ];
    }

    # nuc-proxy
    {
      services.nginx.virtualHosts."nuc-proxy.li7g.com" = {
        forceSSL = true;
        useACMEHost = "vultr.li7g.com";
        locations."/" = {
          proxyPass = "https://nuc.ts.li7g.com";
        };
      };
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
    }
  ];
}
