{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.steam;
  gamescopeCfg = config.programs.gamescope;

  steamFontsDir = pkgs.symlinkJoin {
    name = "steam-fonts-dir";
    paths = cfg.fontPackages;
  };
  steamFonts = pkgs.runCommand "steam-fonts" { preferLocalBuild = true; } ''
    mkdir -p "$out/share"
    ln -s "${steamFontsDir}" "$out/share/fonts"
  '';

  # copy-paste from https://github.com/Cryolitia/nixpkgs/blob/164f66169a0bae512fc445d4f888f78012f05781/nixos/modules/programs/steam.nix
  extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" cfg.extraCompatPackages;
in
{
  options.programs.steam = {
    fontPackages = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = config.fonts.packages;
      defaultText = lib.literalExpression "config.fonts.packages";
      example = lib.literalExpression "with pkgs; [ source-han-sans ]";
      description = ''
        Font packages to use in Steam.
        Defaults to system fonts, but could be overridden to use other fonts — useful for users who would like to customize CJK fonts used in Steam. According to the [upstream issue](https://github.com/ValveSoftware/steam-for-linux/issues/10422#issuecomment-1944396010), Steam only follows the per-user fontconfig configuration.
      '';
    };

    # copy-paste from https://github.com/Cryolitia/nixpkgs/blob/164f66169a0bae512fc445d4f888f78012f05781/nixos/modules/programs/steam.nix
    newPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.steam;
      defaultText = lib.literalExpression "pkgs.steam";
      example = lib.literalExpression ''
        pkgs.steam-small.override {
          extraEnv = {
            MANGOHUD = true;
            OBS_VKCAPTURE = true;
            RADV_TEX_ANISO = 16;
          };
          extraLibraries = p: with p; [
            atk
          ];
        }
      '';
      apply =
        steam:
        steam.override (
          prev:
          {
            extraEnv =
              (lib.optionalAttrs (cfg.extraCompatPackages != [ ]) {
                STEAM_EXTRA_COMPAT_TOOLS_PATHS = extraCompatPaths;
              })
              // (lib.optionalAttrs cfg.extest.enable {
                LD_PRELOAD = "${pkgs.pkgsi686Linux.extest}/lib/libextest.so";
              })
              // (prev.extraEnv or { });
            extraLibraries =
              pkgs:
              let
                prevLibs = if prev ? extraLibraries then prev.extraLibraries pkgs else [ ];
                additionalLibs =
                  with config.hardware.opengl;
                  if pkgs.stdenv.hostPlatform.is64bit then
                    [ package ] ++ extraPackages
                  else
                    [ package32 ] ++ extraPackages32;
              in
              prevLibs ++ additionalLibs;
            extraPkgs = p: (cfg.extraPackages ++ lib.optionals (prev ? extraPkgs) (prev.extraPkgs p));
          }
          // lib.optionalAttrs (cfg.gamescopeSession.enable && gamescopeCfg.capSysNice) {
            buildFHSEnv = pkgs.buildFHSEnv.override {
              # use the setuid wrapped bubblewrap
              bubblewrap = "${config.security.wrapperDir}/..";
            };
          }
        );
      description = ''
        The Steam package to use. Additional libraries are added from the system
        configuration to ensure graphics work properly.
        Use this option to customise the Steam package rather than adding your
        custom Steam to {option}`environment.systemPackages` yourself.
      '';
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [
          gamescope
        ]
      '';
      description = ''
        Additional packages to add to the Steam environment.
      '';
    };
  };
  config = {
    programs.steam.extraPackages = [ steamFonts ];

    programs.steam.package = lib.mkForce cfg.newPackage;
    passthru = {
      inherit steamFonts;
    };
  };
}
