{ config, pkgs, ... }:

{
  # TODO wait for https://nixpk.gs/pr-tracker.html?pr=185116
  # see https://github.com/NixOS/nixpkgs/issues/178345
  boot.initrd.systemd.additionalUpstreamUnits = [ "initrd-udevadm-cleanup-db.service" ];
  boot.initrd.services.udev.rules = ''
    # Mark dm devices as db_persist so that they are kept active after switching root
    SUBSYSTEM=="block", KERNEL=="dm-[0-9]*", ACTION=="add|change", OPTIONS+="db_persist"
  '';
}
