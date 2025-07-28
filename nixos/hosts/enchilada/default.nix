{
  config,
  suites,
  profiles,
  lib,
  pkgs,
  ...
}:
let
  minimal = false;
in
{
  imports =
    suites.base
    ++ [
      ./_boot.nix
      ./_kernel.nix
      ./_gadget
      ./_hardware.nix
    ]
    ++ (
      if minimal then
        [
          profiles.users.root
          profiles.boot.plymouth
        ]
      else
        (
          suites.mobile
          ++ (with profiles; [
            nix.nixbuild
            networking.behind-fw
            networking.fw-proxy
            networking.wireguard-home
            services.flatpak
            services.nginx
            services.acme
            # not working
            # services.fprintd
            virtualization.waydroid
            users.yinfeng
          ])
        )
    );

  config = lib.mkMerge [
    (lib.mkIf minimal {
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };
      networking.useNetworkd = true;
      system.nproc = 8;
    })

    # usb network
    {
      # manual rndis setup
      systemd.services.setup-rndis = {
        script = ''
          eza --tree /sys/class/udc
          gt enable "g1" "a600000.usb"
        '';
        path = with pkgs; [
          eza
          gt
        ];
        wantedBy = [ "gt.target" ];
      };
      systemd.network.networks."50-usb0" = {
        matchConfig = {
          Name = "usb0";
        };
        address = [ "172.16.42.1/24" ];
      };
    }

    # faster build
    {
      documentation.man.generateCaches = false;
    }

    (lib.mkIf (!minimal) (
      lib.mkMerge [
        # desktop
        {
          services.xserver.desktopManager.phosh = {
            enable = true;
            user = "yinfeng";
            group = "users";
            phocConfig = {
              outputs."DSI-1".scale = 3;
            };
          };
          services.gnome.core-apps.enable = true;

          programs.calls.enable = true;
          programs.feedbackd.enable = true;
          environment.systemPackages = with pkgs; [
            chatty
            gnome-console
          ];
          system.nproc = 8;
        }

        # applications
        {
          environment.systemPackages = with pkgs; [
            libssc
            fastfetch
          ];
        }

        # user
        {
          home-manager.users.yinfeng =
            { suites, lib, ... }:
            {
              imports = suites.mobile;

              dconf.settings = {
                "sm/puri/phoc" = {
                  scale-to-fit = true;
                  auto-maximize = true;
                };

                # old gnome configurations
                "org/gnome/settings-daemon/plugins/power" = {
                  power-button-action = "nothing";
                  sleep-inactive-battery-type = "nothing";
                  sleep-inactive-ac-type = "nothing";
                };
                "org/gnome/desktop/session" = {
                  idle-delay = lib.hm.gvariant.mkUint32 60;
                };
              };
            };
          users.users.yinfeng.hashedPasswordFile = lib.mkForce config.sops.secrets."user-pin/yinfeng".path;
          sops.secrets."user-pin/yinfeng" = {
            neededForUsers = true;
            sopsFile = config.sops-file.get "common.yaml";
          };
        }

        # memory
        {
          zramSwap.enable = true;
          swapDevices = [
            {
              device = "/swapfile";
              size = 8192; # 8 GiB
            }
          ];
        }

        # other
        {
          services.tailscale.enable = true;
          networking.campus-network = {
            enable = true;
            auto-login.enable = true;
          };
          # flatpak workarounds
          # services.flatpak.workaround = {
          #   font.enable = true;
          #   icon.enable = true;
          # };
        }
      ]
    ))

    # stateVersion
    { system.stateVersion = "25.05"; }
  ];
}
