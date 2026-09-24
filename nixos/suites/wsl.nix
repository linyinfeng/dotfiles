{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.network.enable = lib.mkDefault true;

  world.profiles.system.types.workstation.enable = lib.mkDefault true;
  world.profiles.i18n.input-method.enable = lib.mkDefault true;
  world.profiles.wsl.settings.enable = lib.mkDefault true;

  world.modules.external.nixos-wsl.enable = lib.mkDefault true;
}
