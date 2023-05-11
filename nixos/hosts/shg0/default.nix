{
  config,
  pkgs,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}: let
  btrfsSubvol = device: subvol: extraConfig:
    lib.mkMerge [
      {
        inherit device;
        fsType = "btrfs";
        options = ["subvol=${subvol}" "compress=zstd"];
      }
      extraConfig
    ];
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in {
  imports =
    suites.server
    ++ (with profiles; [
      networking.behind-fw
      networking.fw-proxy
      networking.wireguard-home
      services.nginx
      services.acme
      services.postgresql
      services.matrix-qq
    ])
    ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
      ./_steam
    ];

  options.hosts.shg0 = {
    listens = lib.mkOption {
      type = with lib.types; listOf anything;
      default = [
        {
          addr = "[::]";
          port = config.ports.https;
          ssl = true;
        }
        {
          addr = "[::]";
          port = config.ports.https-alternative;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = config.ports.https;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = config.ports.https-alternative;
          ssl = true;
        }
      ];
    };
  };

  config = lib.mkMerge [
    {
      boot.loader.grub = {
        enable = true;
        version = 2;
        device = "/dev/vda";
      };
      boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk"];

      boot.tmp.useTmpfs = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227"
        ];
      };

      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["defaults" "size=2G" "mode=755"];
      };
      fileSystems."/persist" = btrfsSubvolMain "@persist" {neededForBoot = true;};
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" {neededForBoot = true;};
      fileSystems."/nix" = btrfsSubvolMain "@nix" {neededForBoot = true;};
      fileSystems."/swap" = btrfsSubvolMain "@swap" {};
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
        fsType = "ext4";
      };
      swapDevices = [
        {
          device = "/swap/swapfile";
        }
      ];
    }

    # acme
    {
      security.acme.certs."main" = {
        extraDomainNames = [
          "shanghai.derp.li7g.com"
        ];
      };
    }

    # nginx
    {
      services.nginx = {
        openFirewall = false;
        virtualHosts."shg0.*" = {
          listen = config.hosts.shg0.listens;
        };
      };
      # only port 443
      networking.firewall.allowedTCPPorts = [443];
    }

    # tailscale derp server
    (
      let
        derperPort = config.ports.https-alternative;
      in {
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
              "shanghai.derp.li7g.com.crt:${config.security.acme.certs."main".directory}/full.pem"
              "shanghai.derp.li7g.com.key:${config.security.acme.certs."main".directory}/key.pem"
            ];
          };
          after = ["network-online.target"];
          wantedBy = ["multi-user.service"];
        };
        systemd.services.derper-watchdog = {
          script = ''
            while true; do
              if ! curl --silent --show-error --output /dev/null \
                https://shanghai.derp.li7g.com:${toString derperPort}
              then
                echo "restart derper server"
                systemctl restart derper
              fi
              sleep 10
            done
          '';
          path = with pkgs; [curl];
          after = ["derper.service"];
          requiredBy = ["derper.service"];
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
