{ lib, ... }:
{
  networking.hostName = lib.mkForce "duo";
  networking.firewall.enable = lib.mkForce true;
  networking.defaultGateway.interface = "usb0";
  nix.enable = lib.mkForce true;
  users.users.root.initialPassword = lib.mkForce null;

  boot.initrd.systemd = {
    enable = lib.mkForce false;
    enableTpm2 = false;
  };
}
