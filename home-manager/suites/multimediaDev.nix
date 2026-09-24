{ lib, ... }:
{
  world.suites.multimedia.enable = lib.mkDefault true;
  world.suites.development.enable = lib.mkDefault true;

  world.profiles.xdg-dirs.enable = lib.mkDefault true;
  world.profiles.vscode.enable = lib.mkDefault true;
  world.profiles.alacritty.enable = lib.mkDefault true;
  world.profiles.wezterm.enable = lib.mkDefault true;
}
