{pkgs, ...}: let
  iosevka-yinfeng = pkgs.iosevka.override {
    privateBuildPlan = {
      family = "Iosevka Yinfeng";
      spacing = "fontconfig-mono";
      serifs = "slab";
      # no need to export character variants and stylistic set
      no-cv-ss = "true";
      ligations = {
        inherits = "haskell";
      };
    };
    set = "yinfeng";
  };
  iosevka-yinfeng-nf = pkgs.stdenv.mkDerivation {
    name = "iosevka-yinfeng-nf";
    src = iosevka-yinfeng;
    nativeBuildInputs = with pkgs; [
      nerd-font-patcher
    ];
    enableParallelBuilding = true;
    unpackPhase = ''
      mkdir -p fonts
      cp -r $src/share/fonts/truetype/. ./fonts/
      chmod u+w -R ./fonts
    '';
    postPatch = ''
      cp ${./NerdFontMakefile} ./Makefile
    '';
  };
in {
  fonts.packages = with pkgs; [
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
    iosevka-yinfeng
    iosevka-yinfeng-nf
    font-awesome
    powerline-fonts
    sarasa-gothic
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
      "Iosevka Yinfeng"
      "Sarasa Mono Slab SC"
    ];
    emoji = [
      "Noto Color Emoji"
    ];
  };

  passthru = {inherit iosevka-yinfeng iosevka-yinfeng-nf;};
}
