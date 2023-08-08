{
  config,
  suites,
  profiles,
  lib,
  pkgs,
  ...
}: {
  imports =
    suites.phone
    ++ (with profiles;
      [
        nix.access-tokens
        nix.nixbuild
        networking.behind-fw
        networking.fw-proxy
        services.flatpak
        virtualization.waydroid
        users.yinfeng
      ]
      ++ [
        # ./_gnome-mobile # crash
      ]);

  config = lib.mkMerge [
    # plasma mobile
    # https://github.com/NixOS/mobile-nixos/blob/master/examples/plasma-mobile/plasma-mobile.nix
    {
      services.xserver = {
        enable = true;
        displayManager.lightdm = {
          enable = true;
          # Workaround for autologin only working at first launch.
          # A logout or session crashing will show the login screen otherwise.
          extraSeatDefaults = ''
            session-cleanup-script=${pkgs.procps}/bin/pkill -P1 -fx ${pkgs.lightdm}/sbin/lightdm
          '';
        };
        desktopManager.plasma5.mobile.enable = true;
        displayManager.autoLogin = {
          enable = true;
          user = "yinfeng";
        };
        displayManager.defaultSession = "plasma-mobile";
      };
      hardware.sensor.iio.enable = true;
      # pulseaudio as main sound server
      hardware.pulseaudio.enable = lib.mkForce true;
      services.pipewire = {
        audio.enable = false;
        pulse.enable = false;
        alsa.enable = false;
        jack.enable = false;
      };
      # services.fprintd.enable = true; # not working
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
        before = ["systemd-networkd.service"];
        wantedBy = ["multi-user.target"];
      };
      systemd.network.networks."40-rndis" = {
        matchConfig = {
          Name = "usb*";
        };
        address = ["172.16.42.1/24"];
      };
    }
    # user
    {
      home-manager.users.yinfeng = {suites, ...}: {
        imports = suites.phone;
      };
      services.openssh.settings.PasswordAuthentication = false;
      users.users.yinfeng.passwordFile = lib.mkForce config.sops.secrets."user-pin/yinfeng".path;
      sops.secrets."user-pin/yinfeng" = {
        neededForUsers = true;
        sopsFile = config.sops-file.get "common.yaml";
      };
    }
    # other
    {
      networking.campus-network = {
        enable = true;
        auto-login.enable = true;
      };
      # broken on enchilada
      networking.fw-proxy.tproxy.enable = false;
      # speed up build
      documentation.man.enable = false;
    }
  ];
}
