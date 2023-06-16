{
  suites,
  profiles,
  lib,
  ...
}: {
  imports =
    suites.phone
    ++ (with profiles; [
      nix.access-tokens
      nix.nixbuild
      networking.wireguard-home
      networking.behind-fw
      networking.fw-proxy
      services.flatpak
      virtualization.waydroid
      users.yinfeng
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
    # services.fprintd.enable = true; # not working
    programs.calls.enable = true;
    home-manager.users.yinfeng = {suites, ...}: {
      imports = suites.phone;
      # nerf font patcher in pinned nixpkgs generates different font family names
      dconf.settings."com/raggesilver/BlackBox".font = lib.mkForce "Iosevka Nerd Font 10";
    };
    networking.campus-network = {
      enable = true;
      auto-login.enable = true;
    };
    # speed up build
    documentation.man.enable = false;
  };
}
