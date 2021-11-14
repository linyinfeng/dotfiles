{ config, pkgs, ... }:

{
  virtualisation.waydroid.enable = true;
  environment.etc."gbinder.d/api-level.conf".text = ''
    [General]
    ApiLevel = 29
  '';
  environment.global-persistence = {
    user.directories = [
      ".local/share/waydroid"
    ];
    directories = [
      "/var/lib/waydroid"
      "/var/lib/lxc/rootfs"
    ];
  };
}
