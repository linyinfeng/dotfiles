{
  config,
  pkgs,
  lib,
  suites,
  profiles,
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

  btrfsSubvolMain = btrfsSubvol "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093";
  btrfsSubvolMobile = btrfsSubvol "/dev/mapper/crypt-mobile";

  cfg = config.hosts.nuc;
in {
  imports =
    suites.server
    ++ suites.development
    ++ suites.virtualization
    ++ (with profiles; [
      nix.access-tokens
      nix.nixbuild
      security.tpm
      networking.network-manager
      networking.behind-fw
      networking.fw-proxy
      services.transmission
      services.jellyfin
      services.samba
      services.vlmcsd
      services.teamspeak
      services.godns
      services.nginx
      services.acme
      services.notify-failure
      services.smartd
      services.postgresql
      programs.service-mail
      programs.tg-send
      users.yinfeng
      users.nianyi
    ])
    ++ [
      ./_hydra
      ./_minecraft
    ];

  config = lib.mkMerge [
    {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
      hardware.enableRedistributableFirmware = true;
      services.fwupd.enable = true;

      services.thermald.enable = true;

      environment.global-persistence.enable = true;
      environment.global-persistence.root = "/persist";

      boot.binfmt.emulatedSystems = [
        "aarch64-linux"
      ];

      systemd.watchdog.runtimeTime = "60s";

      services.fstrim.enable = true;
      services.btrfs.autoScrub = {
        enable = true;
        fileSystems = [
          "/dev/disk/by-uuid/8b982fe4-1521-4a4d-aafc-af22c3961093"
          "/dev/mapper/crypt-mobile"
        ];
      };

      home-manager.users.yinfeng = {suites, ...}: {imports = suites.nonGraphical;};

      boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "vmd" "ahci" "nvme" "usbhid" "uas" "sd_mod"];
      boot.kernelModules = ["kvm-intel"];
      boot.initrd.luks.forceLuksSupportInInitrd = true;
      boot.initrd.kernelModules = ["tpm" "tpm_tis" "tpm_crb"];
      boot.initrd.preLVMCommands = ''
        waitDevice /dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c
        ${pkgs.clevis}/bin/clevis luks unlock -d /dev/disk/by-uuid/b456f27c-b0a1-4b1e-8f2b-91f1826ae51c -n crypt-mobile
      '';
      fileSystems."/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = ["defaults" "size=2G" "mode=755"];
      };
      boot.tmp = {
        useTmpfs = true;
        # reasonable because of swap
        tmpfsSize = "100%";
      };
      fileSystems."/nix" = btrfsSubvolMain "@nix" {neededForBoot = true;};
      fileSystems."/persist" = btrfsSubvolMain "@persist" {neededForBoot = true;};
      fileSystems."/var/log" = btrfsSubvolMain "@var-log" {neededForBoot = true;};
      fileSystems."/swap" = btrfsSubvolMain "@swap" {};
      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/C9A4-3DE6";
        fsType = "vfat";
      };
      swapDevices = [
        {
          device = "/swap/swapfile";
        }
      ];
      fileSystems."/var/lib/transmission" = btrfsSubvolMobile "@bittorrent" {};
      fileSystems."/media/data" = btrfsSubvolMobile "@data" {};
    }

    # godns
    {
      services.godns = {
        ipv4.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = ["nuc" "mc"];
            }
          ];
          ip_type = "IPv4";
          ip_urls = ["https://ifconfig.me"];
        };
        ipv6.settings = {
          domains = [
            {
              domain_name = "li7g.com";
              sub_domains = ["nuc"];
            }
          ];
          ip_type = "IPv6";
          ip_interface = "enp88s0";
        };
      };
    }

    # nginx
    {
      services.nginx = {
        defaultListen = [
          {
            addr = "0.0.0.0";
            port = config.ports.http;
            ssl = false;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.https;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.http-alternative;
            ssl = false;
          }
          {
            addr = "0.0.0.0";
            port = config.ports.https-alternative;
            ssl = true;
          }
          {
            addr = "[::]";
            port = config.ports.http;
            ssl = false;
          }
          {
            addr = "[::]";
            port = config.ports.https;
            ssl = true;
          }
          {
            addr = "[::]";
            port = config.ports.http-alternative;
            ssl = false;
          }
          {
            addr = "[::]";
            port = config.ports.https-alternative;
            ssl = true;
          }
        ];
        virtualHosts."nuc.*" = {
          serverAliases = [
            "nuc-proxy.*"
          ];
          locations."/" = {
            root = ./_www;
          };
        };
      };
      networking.firewall.allowedTCPPorts = with config.ports; [
        http-alternative
        https-alternative
      ];
      networking.firewall.allowedUDPPorts = with config.ports; [
        https-alternative
      ];
    }

    # store serving
    {
      services.nginx = {
        virtualHosts."nuc.*" = {
          locations."/store/" = {
            proxyPass = "http://127.0.0.1:${toString config.ports.nix-serve}/";
            extraConfig = ''
              proxy_max_temp_file_size 0;
            '';
          };
        };
      };
      services.nix-serve = {
        enable = true;
        bindAddress = "0.0.0.0";
        port = config.ports.nix-serve;
        secretKeyFile = config.sops.secrets."cache-li7g-com/key".path;
      };
      sops.secrets."cache-li7g-com/key" = {
        sopsFile = config.sops-file.host;
        restartUnits = ["nix-serve.service"];
      };

      systemd.services.nix-serve = {
        serviceConfig = {
          Group = lib.mkForce "hydra";
          RuntimeDirectory = "nix-serve";
        };
        environment.HOME = "$RUNTIME_DIRECTORY";
      };
    }

    # transmission
    # extra settings for profies.services.transmission
    {
      services.nginx.virtualHosts."transmission.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."/transmission".proxyPass = "http://localhost:${toString config.services.transmission.settings.rpc-port}";
        locations."/files/" = {
          alias = "/var/lib/transmission/Downloads/";
          extraConfig = ''
            charset UTF-8;
            autoindex on;
            auth_basic "transmission";
            auth_basic_user_file ${config.sops.templates."transmission-auth-file".path};
          '';
        };
      };
      users.users.nginx.extraGroups = [config.users.groups.transmission.name];
      sops.templates."transmission-auth-file" = {
        content = ''
          ${config.sops.placeholder."transmission_username"}:${config.sops.placeholder."transmission_hashed_password"}
        '';
        owner = config.users.users.nginx.name;
      };
      sops.secrets."transmission_username" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["nginx.service"];
      };
      sops.secrets."transmission_hashed_password" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["nginx.service"];
      };
      sops.secrets."transmission_password" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["transmission.service"];
      };
    }

    # jellyfin
    {
      # for vaapi support
      hardware.opengl.enable = true;

      services.nginx.virtualHosts."jellyfin.*" = {
        forceSSL = true;
        useACMEHost = "main";
        locations."= /" = {
          extraConfig = ''
            return 302 /web/;
          '';
        };
        locations."/" = {
          proxyPass = "http://localhost:${toString config.ports.jellyfin}";
          extraConfig = ''
            proxy_buffering off;
          '';
        };
        locations."= /web/".proxyPass = "http://localhost:${toString config.ports.jellyfin}/web/index.html";
        locations."/socket" = {
          proxyPass = "http://localhost:${toString config.ports.jellyfin}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
          '';
        };
      };
    }
  ];
}
