{ suites, profiles, ... }:
{
  imports =
    suites.base ++
    (with profiles; [
      networking.network-manager
    ]);

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; };
}
