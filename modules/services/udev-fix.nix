{ config, pkgs, ... }:

{
  # TODO picked from https://github.com/NixOS/nixpkgs/pull/185116
  # see https://github.com/NixOS/nixpkgs/issues/178345
  boot.initrd.systemd.additionalUpstreamUnits = [ "initrd-udevadm-cleanup-db.service" ];
}
