{ pkgs, ... }:

let
  winVirtioIso = pkgs.runCommand "win-virtio-iso" {} ''
    mkdir -p "$out/var/lib/libvirt/images"
    ln -s ${pkgs.win-virtio.src} "$out/var/lib/libvirt/images/win-virtio.iso"
  '';
in
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

  # virtio win
  environment.systemPackages = [
    winVirtioIso
  ];
}
