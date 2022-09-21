{ config, pkgs, modulesPath, suites, ... }:

{
  imports = suites.base ++ [
    "${modulesPath}/installer/netboot/netboot-minimal.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
}
