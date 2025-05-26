{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.fonts;
in
{
  options.fonts.customFonts = {
    enable = lib.mkEnableOption "custom fonts";
  };
  config = {
    fonts.customFonts.enable = lib.mkDefault (lib.elem "workstation" config.system.types);

    fonts.packages =
      with pkgs;
      [
        noto-fonts-emoji

        source-serif
        source-han-serif
        source-sans
        source-han-sans
        source-code-pro

        open-sans
        liberation_ttf
        wqy_zenhei
        wqy_microhei

        jetbrains-mono
        font-awesome
        sarasa-gothic
        # powerline-fonts # conflict with hack

        corefonts
        vistafonts
      ]
      ++ (
        if cfg.customFonts.enable then
          with pkgs;
          [
            iosevka-yinfeng
            # TODO broken
            # iosevka-yinfeng-nf
          ]
        else
          [ pkgs.iosevka ]
      );

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
      monospace =
        lib.optionals cfg.customFonts.enable [
          "IosevkaYinfeng Nerd Font"
        ]
        ++ [ "Sarasa Mono Slab SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
