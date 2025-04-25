{ config, pkgs, ... }:
let
  audioPlugins = with pkgs; [
    # lv2
    neural-amp-modeler-lv2
    # ladspa
  ];
in
{
  home.packages =
    with pkgs;
    [
      # DAW
      reaper

      # sheet music
      lilypond
      frescobaldi
      musescore

      # plugin support
      yabridge
      yabridgectl
    ]
    ++ audioPlugins;
  home.sessionVariables = {
    LV2_PATH = "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/lib/lv2";
    LADSPA_PATH = "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/lib/ladspa";
  };
  home.global-persistence.directories = [
    ".config/REAPER"
    ".config/MuseScore"
    ".local/share/MuseScore"
    ".vst"
    ".vst3"
    ".clap"
  ];
}
