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
      ./cache-overlay.nix
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

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227"
        ];
      };

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
      security.acme.certs."main" = {
        domain = "*.li7g.com";
        extraDomainNames = [
          "*.zt.li7g.com"
          "*.ts.li7g.com"
          "shanghai.derp.li7g.com"
        ];
      };
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

    # well-known
    {
      services.nginx.virtualHosts."li7g.com" =
        {
          forceSSL = true;
          useACMEHost = "main";
          # matrix
          locations."/.well-known/matrix/server".extraConfig = ''
            default_type application/json;
            return 200 '{ "m.server": "matrix.li7g.com:443" }';
          '';
          locations."/.well-known/matrix/client".extraConfig = ''
            add_header Access-Control-Allow-Origin '*';
            default_type application/json;
            return 200 '{ "m.homeserver": { "base_url": "https://matrix.li7g.com" } }';
          '';
          # mastodon
          location."/.well-known/host-meta".extraConfig = ''
            return 301 https://mastodon.li7g.com$request_uri;
          ''
            };
        }

          # portal
          {
            services.nginx.virtualHosts."portal.*" = {
              forceSSL = true;
              useACMEHost = "main";
              locations."/" = {
                root = pkgs.element-web-li7g-com;
              };
            };
            services.portal = {
              host = "portal.li7g.com";
              nginxVirtualHost = "portal.*";
              server.enable = true;
            };
          }

          # dot-tar
          {
            services.nginx.virtualHosts."tar.*" = {
              forceSSL = true;
              useACMEHost = "main";
              locations."/" = {
                proxyPass = "http://localhost:${toString config.ports.dot-tar}";
              };
            };
            services.dot-tar = {
              enable = true;
              config = {
                release = {
                  port = config.ports.dot-tar;
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
            services.nginx.virtualHosts."nuc-proxy.*" = {
              forceSSL = true;
              useACMEHost = "main";
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
