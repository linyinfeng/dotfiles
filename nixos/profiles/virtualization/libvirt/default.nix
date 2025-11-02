{ config, pkgs, ... }:
let
  virtioWinIso = pkgs.runCommand "virtio-win-iso" { } ''
    mkdir -p "$out/share/virtio-win"
    ln -s ${pkgs.virtio-win.src} "$out/share/virtio-win/virtio-win.iso"
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.checkReversePath = false;

  environment.global-persistence.user.directories = [ ".config/libvirt" ];

  environment.systemPackages = [
    # pkgs.libguestfs-with-appliance
    virtioWinIso
  ];
  environment.pathsToLink = [ "/share/virtio-win" ];

  networking.firewall.allowedUDPPorts = [
    config.ports.dns
    config.ports.dhcp-server
  ];
}
