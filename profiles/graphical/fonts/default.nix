{ pkgs, ... }:

{
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra

    source-han-serif
    source-han-serif-japanese
    source-han-serif-korean
    source-han-serif-simplified-chinese
    source-han-serif-traditional-chinese
    source-han-sans
    source-han-sans-japanese
    source-han-sans-korean
    source-han-sans-simplified-chinese
    source-han-sans-traditional-chinese
    source-code-pro

    opensans-ttf
    liberation_ttf
    wqy_zenhei
    wqy_microhei

    jetbrains-mono
    iosevka
    sarasa-gothic
    font-awesome
    powerline-fonts

    symbola
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "Noto Sans"
      "Source Han Sans SC"
      "Source Han Sans TC"
      "Source Han Sans HW"
      "Source Han Sans K"
      "DejaVu Sans"
    ];
    serif = [
      "Noto Serif"
      "Source Han Serif SC"
      "Source Han Serif TC"
      "Source Han Serif HW"
      "Source Han Serif K"
      "DejaVu Serif"
    ];
    monospace = [
      "Noto Sans Mono"
      "DejaVu Sans Mono"
    ];
    emoji = [
      "Noto Color Emoji"
    ];
  };
}
