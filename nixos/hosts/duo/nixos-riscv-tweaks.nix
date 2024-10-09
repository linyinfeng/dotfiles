{ lib, ... }:
{
  networking.hostName = lib.mkForce "duo";
  networking.firewall.enable = lib.mkForce true;
  networking.defaultGateway = lib.mkForce null;
  networking.nameservers = lib.mkForce [ ];
  services.udev.enable = lib.mkForce true;
  services.nscd.enable = lib.mkForce true;
  services.dnsmasq.enable = lib.mkForce false;
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  nix.enable = lib.mkForce true;
  users.users.root.initialPassword = lib.mkForce null;

  boot.initrd.systemd = {
    # enable = lib.mkForce false;
    tpm2.enable = false;
  };

  boot.kernelPatches = [
    {
      name = "nftables";
      patch = null;
      extraStructuredConfig = lib.mapAttrs (_: v: lib.mkForce (v // { optional = false; })) (
        import ./kernel/configs/nftables.config.nix { inherit lib; }
        // import ./kernel/configs/merge.nix { inherit lib; }
      );
    }
  ];

  fileSystems."/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [
      "dmask=077"
      "fmask=177"
    ];
  };
}
