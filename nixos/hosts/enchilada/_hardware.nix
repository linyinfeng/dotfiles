{ lib, pkgs, ... }:
lib.mkMerge [
  # systemd
  {
    systemd.package = pkgs.systemd.override {
      withEfi = false;
    };
    boot.initrd.systemd.tpm2.enable = false;
  }
]
