{
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}:
let
  btrfsSubvol =
    device: subvol: extraConfig:
    lib.mkMerge [
      {
        inherit device;
        fsType = "btrfs";
        options = [
          "subvol=${subvol}"
          "compress=zstd"
        ];
      }
      extraConfig
    ];
  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227";
in
{
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
      services.teamspeak
    ])
    ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
      ./_steam
    ];

  config = lib.mkMerge [
    {
      boot.loader.grub = {
        enable = true;
        device = "/dev/vda";
      };
      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];

      boot.tmp.useTmpfs = true;
      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [ "/dev/disk/by-uuid/9f227a19-d570-449f-b4cb-0eecc5b2d227" ];
      };

      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };
      fileSystems."/persist" = btrfsSubvolMain "@persist" { neededForBoot = true; };
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" { neededForBoot = true; };
      fileSystems."/nix" = btrfsSubvolMain "@nix" { neededForBoot = true; };
      fileSystems."/swap" = btrfsSubvolMain "@swap" { };
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/4a186796-5865-4b47-985c-9354adec09a4";
        fsType = "ext4";
      };
      services.zswap.enable = true;
      swapDevices = [ { device = "/swap/swapfile"; } ];

      system.nproc = 2;
    }

    # nginx
    { services.nginx.defaultHTTPListenPort = 8080; }

    {
      services.rathole = {
        enable = true;
        role = "server";
        settings = {
          server = {
            bind_addr = "[::]:${toString config.ports.rathole}";
            services.minecraft = {
              bind_addr = "[::]:${toString config.ports.minecraft}";
            };
          };
        };
        credentialsFile = config.sops.templates."rathole-toml".path;
      };
      sops.templates."rathole-toml".content = ''
        [server.services.minecraft]
        token = "${config.sops.placeholder."rathole_minecraft_token"}"
      '';
      sops.secrets."rathole_minecraft_token" = {
        terraformOutput.enable = true;
        restartUnits = [ "rathole.service" ];
      };
      networking.firewall.allowedTCPPorts = with config.ports; [
        rathole # default transport is tcp
        minecraft
      ];
    }

    (lib.mkIf (!config.system.is-vm) {
      systemd.network.networks."40-ens" = {
        matchConfig = {
          # ethtool -i
          Driver = [ "virtio_net" ];
        };
        networkConfig = {
          DHCP = "yes";
        };
      };
    })

    # stateVersion
    { system.stateVersion = "24.05"; }
  ];
}
