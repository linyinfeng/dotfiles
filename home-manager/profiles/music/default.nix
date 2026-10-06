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
    neuralrack # NAM + IR chain, also ships CLAP/VST2/VST3
    ratatouille-lv2 # two-model blend with phase alignment
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
        qpwgraph # PipeWire patchbay

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
      # REAPER scans ~/.lv2 by default but ignores LV2_PATH, so point ~/.lv2 at
      # the profile instead of listing paths in REAPER's own preferences
      home.file.".lv2".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/lv2";

      # home.packages lands in /etc/profiles/per-user/$USER, not in a stateHome
      # profile, so the search paths must follow profileDirectory
      home.sessionVariables = {
        LADSPA_PATH = "${config.home.profileDirectory}/lib/ladspa";
        LV2_PATH = "${config.home.profileDirectory}/lib/lv2";
        CLAP_PATH = "${config.home.profileDirectory}/lib/clap";
      };
    })
  ]
)
