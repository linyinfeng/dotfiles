{ config, lib, ... }:
{
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  time.timeZone = lib.mkDefault "Asia/Shanghai";

  system.etc.overlay.enable = lib.mkIf (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.6") (
    lib.mkDefault true
  );
  # TODO wait for sops-nix support
  # services.userborn.enable = true;
  users.mutableUsers = lib.mkDefault false;
}
