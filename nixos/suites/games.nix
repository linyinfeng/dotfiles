{ lib, ... }:
{
  world.profiles.graphical.game.steam.enable = lib.mkDefault true;
  world.profiles.graphical.game.gamescope.enable = lib.mkDefault true;
}
