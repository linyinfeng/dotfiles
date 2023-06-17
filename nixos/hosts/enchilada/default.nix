{
  suites,
  profiles,
  lib,
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

  config = {
    mobile.beautification.splash = true;
    services.xserver.desktopManager.gnome.enable = true;
    # TODO broken
    # mobile.boot.stage-1.usb.features = ["rndis"];
    # manual rndis setup
    networking.useNetworkd = true;
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
    networking.fw-proxy.tproxy.enable = false; # broken on enchilada
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
    programs.calls.enable = true;
    home-manager.users.yinfeng = {suites, ...}: {
      imports = suites.phone;
      dconf.settings."org/gnome/desktop/a11y/applications" = {
        screen-keyboard-enabled = true;
      };
    };
    networking.campus-network = {
      enable = true;
      auto-login.enable = true;
    };
    # speed up build
    documentation.man.enable = false;
  };
}
