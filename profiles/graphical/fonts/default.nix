{ pkgs, lib, ... }:

{
  fonts.fonts = with pkgs; [
    noto-fonts-emoji

    source-serif-pro
    source-han-serif
    source-sans-pro
    source-han-sans
    source-code-pro

    open-sans
    liberation_ttf
    wqy_zenhei
    wqy_microhei

    jetbrains-mono
    iosevka
    font-awesome
    powerline-fonts
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = lib.mkBefore [
      "Source Sans 3"
      "Source Han Sans SC"
      "Source Han Sans TC"
      "Source Han Sans HW"
      "Source Han Sans K"
    ];
    serif = lib.mkBefore [
      "Source Serif 4"
      "Source Han Serif SC"
      "Source Han Serif TC"
      "Source Han Serif HW"
      "Source Han Serif K"
    ];
    # respect powerline font settings in core
    monospace = lib.mkAfter [
      "Iosevka"
    ];
    emoji = lib.mkBefore [
      "Noto Color Emoji"
    ];
  };
}
