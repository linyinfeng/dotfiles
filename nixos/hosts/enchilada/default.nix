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
    # desktop
    {
      services.xserver = {
        enable = true;
        displayManager.lightdm = {
          enable = true;
          # # Workaround for autologin only working at first launch.
          # # A logout or session crashing will show the login screen otherwise.
          # extraSeatDefaults = ''
          #   session-cleanup-script=${pkgs.procps}/bin/pkill -P1 -fx ${pkgs.lightdm}/sbin/lightdm
          # '';
        };
        desktopManager.plasma5.mobile.enable = true;
        displayManager.autoLogin = {
          enable = true;
          user = "yinfeng";
        };
        displayManager.defaultSession = "plasma-mobile";
      };
      i18n.inputMethod.enabled = "fcitx5";
      hardware.sensor.iio.enable = true;
      # pulseaudio as main sound server
      hardware.pulseaudio.enable = lib.mkForce true;
      services.pipewire = {
        audio.enable = false;
        pulse.enable = false;
        alsa.enable = false;
        jack.enable = false;
      };
      programs.dconf.enable = true;
      # services.fprintd.enable = true; # not working
      environment.systemPackages = with pkgs; [
        discover
      ];
    }

    # tweaks
    {
      # not working
      systemd.services.msm-modem-uim-selection.enable = lib.mkForce false;
    }

    # applications
    {
      environment.systemPackages = with pkgs; [
        telegram-desktop
        element-desktop
        qq
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

            ip address add 172.16.42.1/24 dev usb0
          fi
          ip link set up dev usb0
        '';
        path = with pkgs; [
          iproute2
        ];
        wantedBy = ["multi-user.target"];
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
        path = with pkgs; [
          nftables
        ];
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
      services.flatpak.workaround = {
        font.enable = true;
        icon.enable = true;
      };
    }
  ];
}
