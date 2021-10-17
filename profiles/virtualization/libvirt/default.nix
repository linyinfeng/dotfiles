{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.checkReversePath = false;

  environment.global-persistence = {
    directories = [
      "/var/lib/libvirt"
    ];
    user.directories = [
      ".config/libvirt"
    ];
  };
}
