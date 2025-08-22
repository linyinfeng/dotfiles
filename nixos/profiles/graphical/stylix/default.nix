{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    image = "${pkgs.nixos-artwork.wallpapers.catppuccin-latte}/share/backgrounds/nixos/nixos-wallpaper-catppuccin-latte.png";
    polarity = "either";
    fonts = {
      serif = {
        name = "serif";
      };
      sansSerif = {
        name = "sans-serif";
      };
      monospace = {
        name = "monospace";
      };
      emoji = {
        name = "emoji";
      };
    };
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      light = "Papirus-Light";
      dark = "Papirus-Dark";
    };
  };
}
