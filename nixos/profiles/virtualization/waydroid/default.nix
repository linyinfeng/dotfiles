{
  config,
  pkgs,
  lib,
  ...
}: {
  virtualisation.waydroid.enable = true;
  environment.etc."gbinder.d/waydroid.conf".text = lib.mkForce ''
    [General]
    ApiLevel = 30
  '';
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
  ];
  environment.global-persistence.user.directories = [
    ".local/share/waydroid"
  ];
}
