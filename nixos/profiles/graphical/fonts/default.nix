{
  pkgs,
  ...
}:
{
  config = {
    fonts.packages = with pkgs; [
      source-serif
      source-han-serif
      source-sans
      source-han-sans
      source-code-pro

      inter

      open-sans
      liberation_ttf
      wqy_zenhei
      wqy_microhei

      jetbrains-mono
      font-awesome
      sarasa-gothic

      corefonts
      vistafonts

      nerd-fonts.iosevka-term-slab

      noto-fonts-emoji
      material-design-icons
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [
        "Source Sans 3"
        "Source Han Sans SC"
        "Source Han Sans TC"
        "Source Han Sans HW"
        "Source Han Sans K"
      ];
      serif = [
        "Source Serif 4"
        "Source Han Serif SC"
        "Source Han Serif TC"
        "Source Han Serif HW"
        "Source Han Serif K"
      ];
      monospace = [
        "IosevkaTermSlab Nerd Font"
        "Sarasa Mono Slab SC"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
