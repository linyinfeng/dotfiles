{
  lib,
  pkgs,
  ...
}:
let
  gtkThemes = pkgs.symlinkJoin {
    name = "gtk-themes";
    paths = with pkgs; [ adw-gtk3 ];
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.file.".local/share/themes".source = "${gtkThemes}/share/themes";

  gtk = {
    enable = true;
    theme.name = "adw-gtk3";
    gtk4.theme = null;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita";
  };
}
