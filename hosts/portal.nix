{ config, suites, lib, ... }:

let
  dotTarHost = "tar.li7g.com";
  dotTarPort = 8001;
  grafanaPort = 8002;
  prometheusPort = 8003;
  prometheusNodeExporterPort = 8004;
in
{
  imports =
    suites.server ++
    suites.acme;

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

      services.scheduled-reboot.enable = true;

      services.nginx = {
        enable = true;
      };
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      services.nginx.virtualHosts.${config.services.portal.host} = {
        addSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString grafanaPort}";
          proxyWebsockets = true;
        };
      };
      services.portal = {
        host = "portal.li7g.com";
        server.enable = true;
      };
      services.grafana = {
        enable = true;
        domain = dotTarHost;
        port = grafanaPort;
        addr = "127.0.0.1";
      };
      services.prometheus = {
        enable = true;
        port = prometheusPort;
        extraFlags = [
          "--web.enable-admin-api"
        ];
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = prometheusNodeExporterPort;
          };
        };
        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [{
              targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
            }];
          }
          {
            job_name = "node";
            static_configs = [{
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            }];
          }
        ];
      };
      services.nginx.virtualHosts.${dotTarHost} = {
        addSSL = true;
        enableACME = true;
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

      fileSystems."/" =
        {
          device = "/dev/disk/by-uuid/c02e1983-731b-4aab-96dc-73e594901c80";
          fsType = "ext4";
        };

      swapDevices =
        [{ device = "/dev/disk/by-uuid/961406a7-4dac-4d45-80e9-ef9b0d4fab99"; }];
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens3.useDHCP = true;
      };
    }
  ];
}
