{
  config,
  suites,
  profiles,
  lib,
  modulesPath,
  ...
}:
let
  inherit (config.networking) hostName;
  hostData = config.lib.self.data.hosts.${hostName};
in
{
  imports =
    suites.overseaServer
    ++ (with profiles; [
      programs.tg-send
      services.nginx
      services.acme
      services.portal-server
      services.postgresql
      services.atuin
      services.nuc-proxy
      services.cache-overlay
      services.sicp-tutorials
    ])
    ++ [ (modulesPath + "/profiles/qemu-guest.nix") ];

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
        "virtio_blk"
      ];

      boot.tmp.cleanOnBoot = true;
      environment.global-persistence.enable = false;

      fileSystems."/" = {
        device = "/dev/vda1";
        fsType = "ext4";
      };
      services.zswap.enable = true;
      swapDevices = [
        { device = "/dev/vda2"; }
        {
          device = "/swapfile";
          size = 4096; # 4 GiB
        }
      ];

      system.nproc = 1;
    }

    (lib.mkIf (!config.system.is-vm) {
      systemd.network.networks."40-ens3" = {
        matchConfig = {
          Name = "ens3";
        };
        DHCP = "ipv4";
        addresses = [
          {

            Address =
              let
                address =
                  assert lib.length hostData.endpoints_v6 == 1;
                  lib.elemAt hostData.endpoints_v6 0;
              in
              "${address}/64";
          }
        ];
        dns = [
          "8.8.8.8"
          "8.8.4.4"
          "2001:4860:4860:0:0:0:0:8888"
          "2001:4860:4860:0:0:0:0:8844"
        ];
        routes = [ { Gateway = "2404:8c80:85:1011::1"; } ];
      };
    })

    # topology
    {
      topology.self.interfaces.ens3 = {
        network = "internet";
        renderer.hidePhysicalConnections = config.topology.tidy;
        physicalConnections = [
          (config.lib.topology.mkConnection "internet" "*")
        ];
      };
    }

    # stateVersion
    { system.stateVersion = "24.11"; }
  ];
}
