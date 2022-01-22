{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.checkReversePath = false;

  environment.global-persistence.user.directories = [
    ".config/libvirt"
  ];
}
