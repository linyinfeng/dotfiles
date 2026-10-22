{
  self,
  inputs,
  lib,
  config,
  getSystem,
  ...
}:
let
  packages = [
    inputs.sops-nix.overlays.default
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.default
    inputs.nur.overlays.default
    inputs.nix-gc-s3.overlays.default
    inputs.oranc.overlays.default
    inputs.ace-bot.overlays.default
    inputs.commit-notifier.overlays.default
    inputs.pastebin.overlays.default
    inputs.emacs-overlay.overlay
    inputs.flat-flake.overlays.default
    inputs.deploy-rs.overlays.default
    inputs.nix-topology.overlays.default
    inputs.nix-alien.overlays.default
    inputs.kukui-nixos.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned # but actually not pinned
    inputs.nix-cache-overlay.overlays.default
    inputs.hongbao-rpn.overlays.default
    inputs.tsukkomi.overlays.default
    inputs.llm-agents.overlays.shared-nixpkgs
    inputs.nizctl.overlay
    (
      _final: prev:
      let
        inherit (prev.stdenv.hostPlatform) system;
      in
      (self.lib.maybeAttrByPath "comma-with-db" inputs [
        "nix-index-database"
        "packages"
        system
        "comma-with-db"
      ])
      // (self.lib.maybeAttrByPath "nix-index-with-db" inputs [
        "nix-index-database"
        "packages"
        system
        "nix-index-with-db"
      ])
      // (self.lib.maybeAttrByPath "zen-browser" inputs [
        "zen-browser"
        "packages"
        system
        "zen-browser"
      ])
    )
    (final: prev: {
      # scoped overlays
      mc-config-nuc = inputs.mc-config-nuc.overlays.default final prev;
      lanzaboote = inputs.lanzaboote.overlays.default final prev;
      mobile-nixos = import "${inputs.mobile-nixos}/overlay/overlay.nix" final prev;
    })
    (
      final: prev:
      let
        # piper-tts reaches pyopenjtalk-plus through calibre; its test_frontend
        # asserts the TypeError wording Cython switched away from in 3.2.
        piperPython = prev.python3.override {
          self = piperPython;
          packageOverrides = _pyFinal: pyPrev: {
            pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                ../patches/pyopenjtalk-plus-cython-error-message.patch
              ];
            });
          };
        };
        # qt 6.12's uic rejects the leading "::" of this .ui file's class names.
        fixMozc =
          drv:
          drv.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
                --replace-fail "::mozc::" "mozc::"
            '';
          });
        # configure only installs the python bindings when `python3` is on PATH.
        fixSpeechd =
          drv:
          drv.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.python3 ];
          });
        speechd-minimal = fixSpeechd prev.speechd-minimal;
        # TODO wait for NixOS/nixpkgs#573479 in nixos-unstable
        dropSphinxMan =
          drv:
          drv.overrideAttrs (old: {
            outputs = builtins.filter (o: o != "man") (old.outputs or [ "out" ]);
            sphinxBuilders = builtins.filter (b: b != "man") (old.sphinxBuilders or [ "html" ]);
          });
      in
      {
        # adjustment
        nixVersions = prev.nixVersions // {
          selected = final.nixVersions.latest;
        };
        nix = final.nixVersions.selected;
        gnuradio = prev.gnuradio.override {
          unwrapped = prev.gnuradio.unwrapped.override {
            soapysdr = final.soapysdr-with-plugins;
          };
        };
        # calibre only runs piper's inference CLI; the default `withTrain` pulls
        # the whole training stack (librosa -> scikit-learn, torch, lightning),
        # and scikit-learn's checks fail on the emulated aarch64 builder.
        calibre = prev.calibre.override {
          inherit speechd-minimal;
          piper-tts = prev.piper-tts.override {
            python3Packages = piperPython.pkgs;
            withTrain = false;
          };
        };
        speechd = fixSpeechd prev.speechd;
        inherit speechd-minimal;
        reuse = dropSphinxMan prev.reuse;
        # the aarch64 node module links against tpm2-tss, which upstream leaves
        # out of the inputs its ELF fixup resolves against
        chatgpt-unwrapped =
          (prev.callPackage "${inputs.llm-agents}/packages/chatgpt/unwrapped.nix" {
            flake = inputs.llm-agents;
            formatelf = prev.llm-agents.formatelf;
          }).overrideAttrs
            (old: {
              buildInputs =
                (old.buildInputs or [ ]) ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [ prev.tpm2-tss ];
            });
        llm-agents = prev.llm-agents // {
          chatgpt = prev.llm-agents.chatgpt.override { inherit (final) chatgpt-unwrapped; };
        };
        zerotierone = prev.zerotierone.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../patches/zerotierone-increase-world-max-roots.patch ];
        });
        mozc = fixMozc prev.mozc;
        # built from the same source, and from the mozc it was instantiated with
        ibus-engines = prev.ibus-engines // {
          mozc = fixMozc prev.ibus-engines.mozc;
        };
        fcitx5-mozc = prev.fcitx5-mozc.override { inherit (final) mozc; };
        blender = prev.blender.override {
          # cudaSupport = true; # TODO broken
        };
        vscode = final.symlinkJoin {
          inherit (prev.vscode) pname version meta;
          paths = [ prev.vscode ];
          buildInputs = [ final.makeWrapper ];
          # TODO remove --password-store=gnome-libsecret
          # wait for https://github.com/microsoft/vscode/issues/187338
          postBuild = ''
            wrapProgram "$out/bin/code" \
              --add-flags --password-store=gnome-libsecret
          '';
        };
      }
    )
  ]
  ++ [ inputs.angrr.overlays.default ];

  nixpkgsConfig = {
    allowUnfree = true;
    # cudaSupport = true;
    # rocmSupport = true;
    # TODO wait for mautrix-telegram, matrix-qq
    allowInsecurePredicate =
      p:
      (p.pname or null) == "olm"
      # zotero 10's runtime, EOL since 2026-10-13; drop once zotero 11 supports ESR 153
      || (p.pname or null) == "firefox-esr-140-bin-unwrapped"
      || (
        (p.pname or null) == "electron"
        && lib.elem (lib.versions.major (p.version or null)) [
          "27"
          "28"
        ]
      );
  };

  alternativeChannels = nixpkgsArgs: {
    unstable = import inputs.nixpkgs nixpkgsArgs;
    latest = import inputs.nixpkgs-latest nixpkgsArgs;
    unstable-small = import inputs.nixpkgs-unstable-small nixpkgsArgs;
    stable = import inputs.nixpkgs-stable nixpkgsArgs;
  };
  # Derive the channel arguments from the pkgs being overlaid, so the overlay
  # list below is independent of which system the caller evaluates it for.
  channelsOf =
    final:
    alternativeChannels {
      config = nixpkgsConfig;
      localSystem = final.stdenv.buildPlatform.system;
      crossSystem =
        if final.stdenv.hostPlatform.system == final.stdenv.buildPlatform.system then
          null
        else
          final.stdenv.hostPlatform.system;
    };
  earlyFixes = [
    (final: _prev: {
      # maintained packages
      godns = (channelsOf final).latest.godns;
    })
  ];
  lateFixes = [
    (final: prev: {
      shim-unsigned = (channelsOf final).stable.shim-unsigned; # TODO fix
      nginx =
        if lib.versionAtLeast prev.nginx.version "1.30.1" then
          prev.nginx
        else
          # TODO wait for https://nixpkgs-tracker.ocfox.me/?pr=519893
          (channelsOf final).latest.nginx;
    })
  ];

  allOverlays = earlyFixes ++ packages ++ lateFixes;
in
{
  flake.overlays.all = lib.composeManyExtensions allOverlays;

  # The merged nixpkgs config (dotfiles' own plus the flake modules'), per
  # system, so downstream flakes can reuse it alongside overlays.all.
  flake.libs.nixpkgsConfig = lib.genAttrs config.systems (system: (getSystem system).nixpkgs.config);

  perSystem =
    { system, ... }:
    lib.mkMerge [
      # common nixpkgs options
      {
        nixpkgs = {
          config = nixpkgsConfig;
          overlays = allOverlays;
        };
      }
      (lib.mkIf (system == "loongarch64-linux") {
        # cross from x86_64-linux
        nixpkgs.localSystem = {
          system = "x86_64-linux";
        };
        nixpkgs.crossSystem = {
          inherit system;
        };
      })
    ];

  # special checks
  flake.checks = {
    "x86_64-linux" =
      let
        inherit ((getSystem "x86_64-linux").allModuleArgs) pkgs;
      in
      {
        "package/blender" = pkgs.blender;
        "package/gnuradio" = pkgs.gnuradio;
      };
  };
}
