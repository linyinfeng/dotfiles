{
  config,
  lib,
  pkgs,
  ...
}:
let
  audioPlugins = with pkgs; [
    # lv2
    neural-amp-modeler-lv2
    sfizz-ui
    # ladspa
  ];
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
  lib.mkMerge [
    {
      home.packages = with pkgs; [
        # DAW
        reaper

        # sheet music
        lilypond
        frescobaldi
        # musescore # TODO broken

        # midi
        timidity
      ];
      home.global-persistence.directories = [
        ".config/MuseScore"
        ".config/REAPER"
        ".local/share/MuseScore"
      ];
    }
    (lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 {
      # plugin support: yabridge is a Wine-based VST bridge, upstream ships x86_64-linux only
      home.packages =
        with pkgs;
        [
          yabridge
          yabridgectl
        ]
        ++ audioPlugins;
      home.global-persistence.directories = [
        ".clap"
        ".vst"
        ".vst3"
      ];
      home.sessionVariables = {
        LADSPA_PATH = "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/lib/ladspa";
        LV2_PATH = "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/lib/lv2";
      };
    })
  ]
)
