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
          services.xserver.desktopManager.gnome.enable = true;
          hardware.sensor.iio.enable = true;
          # pulseaudio as main sound server
          hardware.pulseaudio.enable = lib.mkForce true;
          services.pipewire = {
            audio.enable = false;
            pulse.enable = false;
            alsa.enable = false;
            jack.enable = false;
          };
          programs.calls.enable = true;
          programs.dconf.enable = true;
          services.fprintd.enable = true;
          environment.systemPackages = with pkgs; [
            chatty
            megapixels
          ];
          system.nproc = 8;
        }

        # applications
        {
          environment.systemPackages = with pkgs; [
            # currently nothing
          ];
        }

        # usb network
        {
          # TODO broken
          # mobile.boot.stage-1.usb.features = ["rndis"];
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
            { suites, ... }:
            {
              imports = suites.phone;
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

        # waydroid
        {
          services.udev = {
            extraRules = ''
              ACTION=="add", SUBSYSTEM=="net", KERNEL=="waydroid0", \
                RUN+="${config.networking.fw-proxy.scripts}/bin/fw-tproxy-if add waydroid0"
            '';
            path = with pkgs; [ nftables ];
          };
        }

        # other
        {
          networking.campus-network = {
            enable = true;
            auto-login.enable = true;
          };
          # speed up build
          documentation.man.enable = false;
          # disable periodic store optimisation
          nix = {
            settings.auto-optimise-store = true;
            optimise.automatic = false;
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
    { system.stateVersion = "24.05"; }
  ];
}
