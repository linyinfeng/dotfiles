{ pkgs, ... }:
{
  # TODO switch to latest LTS LTO kernel when available
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts-lto;
}
