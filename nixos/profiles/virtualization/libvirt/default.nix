{ config, pkgs, ... }:
let
  winVirtioIso = pkgs.runCommand "win-virtio-iso" { } ''
    mkdir -p "$out/share/win-virtio"
    ln -s ${pkgs.win-virtio.src} "$out/share/win-virtio/win-virtio.iso"
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.checkReversePath = false;

  environment.global-persistence.user.directories = [ ".config/libvirt" ];

  # virtio win
  environment.systemPackages = [ winVirtioIso ];
  environment.pathsToLink = [ "/share/win-virtio" ];

  networking.firewall.allowedUDPPorts = [
    config.ports.dns
    config.ports.dhcp-server
  ];
}
