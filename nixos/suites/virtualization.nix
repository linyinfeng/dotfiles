{ lib, ... }:
{
  world.profiles.virtualization.libvirt.enable = lib.mkDefault true;
  world.profiles.virtualization.podman.enable = lib.mkDefault true;
  world.profiles.virtualization.incus.enable = lib.mkDefault true;
}
