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
    x42-plugins # meters, oscilloscope, tuner, etc.
    # ladspa
  ];

  nixVst3Plugins = pkgs.buildEnv {
    name = "nix-vst3-plugins";
    paths = audioPlugins;
    pathsToLink = [ "/lib/vst3" ];
  };

  # Carla dlopens libjack.so.0 at runtime; wrap its entrypoints with PipeWire's
  # JACK library just like REAPER so desktop launches and the systemd service
  # connect to PipeWire without `pw-jack`.
  carla = pkgs.symlinkJoin {
    name = "carla-${pkgs.carla.version}";
    paths = [ pkgs.carla ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in "$out"/bin/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          target=$(readlink -f "$bin")
          rm "$bin"
          makeWrapper "$target" "$bin" \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        fi
      done
    '';
  };

  carlaProject = "${config.xdg.userDirs.documents}/Carla/patchbay.carxp";

  carlaWaitForPipeWire = pkgs.writeShellApplication {
    name = "carla-wait-for-pipewire";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      pipewire
    ];
    text = ''
      # wireplumber.service is Type=simple, so ALSA/MIDI ports may not exist
      # yet right after boot; wait briefly for ExternalPatchbay restoration
      # while staying instant on manual starts.
      for ((attempt = 1; attempt <= 20; attempt++)); do
        ports="$(pw-link -i 2>/dev/null || true)"
        if grep -q '^alsa_output\.' <<<"$ports"; then
          if ((attempt > 1)); then
            sleep 1
          fi
          exit 0
        fi
        sleep 0.5
      done
    '';
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
  lib.mkMerge [
    {
      home.packages =
        with pkgs;
        [
          # DAW
          (reaper.override { jackLibrary = pipewire.jack; })
          qpwgraph # PipeWire patchbay

          # sheet music
          lilypond
          frescobaldi
          # musescore # TODO broken

          # midi
          timidity
        ]
        ++ [
          carla
        ];
      home.global-persistence.directories = [
        ".config/MuseScore"
        ".config/REAPER"
        ".config/falkTX"
        ".local/share/MuseScore"
      ];

      systemd.user.services.carla = {
        Unit = {
          Description = "Carla headless audio patchbay";
          After = [
            "pipewire.service"
            "wireplumber.service"
          ];
          Requires = [ "pipewire.service" ];
          Wants = [ "wireplumber.service" ];
          PartOf = [ "pipewire.service" ];
          ConditionPathExists = carlaProject;
        };
        Service = {
          Type = "simple";
          Environment = [ "PYTHONUNBUFFERED=1" ];
          ExecStartPre = lib.getExe carlaWaitForPipeWire;
          ExecStart = "${carla}/bin/carla --no-gui \"${carlaProject}\"";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
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

      # ~/.vst3 is a mutable persisted dir for yabridge, and Carla's VST3 scanner
      # uses os.walk without followlinks=True, so materialize a real ~/.vst3/nix
      # directory instead of a single directory symlink.
      home.file.".vst3/nix" = {
        source = "${nixVst3Plugins}/lib/vst3";
        recursive = true;
      };

      # home.packages lands in /etc/profiles/per-user/$USER, not in a stateHome
      # profile, so the search paths must follow profileDirectory
      home.sessionVariables = {
        LADSPA_PATH = "${config.home.profileDirectory}/lib/ladspa";
        LV2_PATH = "${config.home.profileDirectory}/lib/lv2";
        CLAP_PATH = "${config.home.profileDirectory}/lib/clap";
      };
      systemd.user.services.carla.Service.Environment = [
        "LADSPA_PATH=${config.home.profileDirectory}/lib/ladspa"
        "LV2_PATH=${config.home.profileDirectory}/lib/lv2"
      ];
    })
  ]
)
