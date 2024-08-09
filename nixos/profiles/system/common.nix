{ lib, ... }:
{
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  time.timeZone = lib.mkDefault "Asia/Shanghai";

  system.etc.overlay.enable = true;
  # TODO wait for sops-nix support
  # services.userborn.enable = true;
  users.mutableUsers = lib.mkDefault false;
}
