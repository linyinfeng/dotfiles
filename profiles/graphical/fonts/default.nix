{ pkgs, lib, ... }:

{
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra

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
    sarasa-gothic
    font-awesome
    powerline-fonts

    symbola
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = lib.mkBefore [
      "Source Sans Pro"
      "Source Han Sans SC"
      "Source Han Sans TC"
      "Source Han Sans HW"
      "Source Han Sans K"
    ];
    serif = lib.mkBefore [
      "Source Serif Pro"
      "Source Han Serif SC"
      "Source Han Serif TC"
      "Source Han Serif HW"
      "Source Han Serif K"
    ];
    # respect powerline font settings in core
    monospace = lib.mkAfter [
      "Noto Sans Mono"
      "DejaVu Sans Mono"
    ];
    emoji = lib.mkBefore [
      "Noto Color Emoji"
    ];
  };
}
