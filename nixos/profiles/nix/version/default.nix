{ pkgs, lib, ... }:
{
  # TODO workaround for nixos-riscv
  nix.package = lib.mkDefault (pkgs.nixVersions.latest or pkgs.nixVersions.unstable);
  # nix.package = lib.mkDefault pkgs.nixVersions.latest;
}
