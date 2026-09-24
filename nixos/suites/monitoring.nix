{ lib, ... }:
{
  world.profiles.services.telegraf.enable = lib.mkDefault true;
  world.profiles.services.telegraf-system.enable = lib.mkDefault true;
  world.profiles.services.alloy.enable = lib.mkDefault true;
}
