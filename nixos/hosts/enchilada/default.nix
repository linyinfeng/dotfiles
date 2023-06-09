{
  suites,
  profiles,
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
    ])
    ++ [];

  config = {
    mobile = {
      beautification.spalsh = true;
      adbd.enable = true;
      boot.stage-1 = {
        networking.enable = true;
        ssh.enable = true;
      };
    };
    services.xserver.desktopManager.gnome.enable = true;
    hardware.sensor.iio.enable = true;
    programs.calls.enable = true;
    home-manager.users.yinfeng = {
      home.graphical = false; # specify all desktop applications manually
    };
  };
}
