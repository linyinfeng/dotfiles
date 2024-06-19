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
    if minimal then
      [
        ./kernel.nix
        profiles.users.root
      ]
    else
      (
        suites.phone
        ++ (
          with profiles;
          [
            nix.access-tokens
            nix.nixbuild
            networking.behind-fw
            networking.fw-proxy
            services.flatpak
            services.nginx
            services.acme
            virtualization.waydroid
            users.yinfeng
          ]
          ++ [ ./kernel.nix ]
        )
      );

  config = lib.mkMerge [
    (lib.mkIf minimal {
      mobile.boot.stage-1.gui.enable = false;
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
      };
      networking.networkmanager.enable = true;
      networking.useNetworkd = true;

      nixpkgs.localSystem.config = "aarch64-unknown-linux-gnu";
      system.nproc = 8;
    })

    (lib.mkIf (!minimal) (
      lib.mkMerge [
        {
          # mobile-nixos stage-1 only handles /init instead of /prepare-root
          boot.initrd.systemd.enable = lib.mkForce false;
        }

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
          services.gnome.core-utilities.enable = true;

          # not working
          # services.fprintd.enable = true;
          programs.calls.enable = true;
          services.fprintd.enable = true;
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

        # usb network
        {
          # manual rndis setup
          systemd.services.setup-rndis = {
            script = ''
              cd /sys/kernel/config/usb_gadget/g1
              if [ ! -e functions/rndis.usb0 ]; then
                mkdir functions/rndis.usb0
                ln -s functions/rndis.usb0 configs/c.1/rndis
                (cd /sys/class/udc; echo *) > UDC
              fi
            '';
            path = with pkgs; [ iproute2 ];
            wantedBy = [ "multi-user.target" ];
          };
          systemd.network.networks."50-usb0" = {
            matchConfig = {
              Name = "usb0";
            };
            address = [ "172.16.42.1/24" ];
          };
        }

        # user
        {
          home-manager.users.yinfeng =
            { suites, lib, ... }:
            {
              imports = suites.phone;

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
          # speed up build
          documentation.man.enable = false;
          # flatpak workarounds
          # services.flatpak.workaround = {
          #   font.enable = true;
          #   icon.enable = true;
          # };
        }
      ]
    ))

    # stateVersion
    { system.stateVersion = "24.05"; }
  ];
}
