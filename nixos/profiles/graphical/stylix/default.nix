{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-light.yaml";
    image = "${pkgs.nixos-artwork.wallpapers.nineish}/share/backgrounds/nixos/nix-wallpaper-nineish.png";
    polarity = "light";
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
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
  ];
  home-manager.sharedModules = [
    {
      stylix.targets = {
        vscode.enable = false;
      };
    }
  ];
}
