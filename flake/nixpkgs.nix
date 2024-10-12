{
  self,
  inputs,
  lib,
  ...
}:
let
  packages = [
    (
      final: _prev:
      let
        mkEmptyPkg = name: final.runCommand name { } "touch $out";
      in
      {
        # spacial packages
        eval-only-check = mkEmptyPkg "eval-only-check";
      }
    )

    inputs.sops-nix.overlays.default
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.singleRepoNur
    inputs.nix-gc-s3.overlays.default
    inputs.oranc.overlays.default
    inputs.ace-bot.overlays.default
    inputs.commit-notifier.overlays.default
    inputs.angrr.overlays.default
    inputs.pastebin.overlays.default
    inputs.emacs-overlay.overlay
    inputs.flat-flake.overlays.default
    inputs.deploy-rs.overlays.default
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
      // (self.lib.maybeAttrByPath "nix-fast-build" inputs [
        "nix-fast-build"
        "packages"
        system
        "default"
      ])
      // (self.lib.maybeAttrByPath "lantian" inputs [
        "lantian"
        "packages"
        system
      ])
      // (self.lib.maybeAttrByPath "niri-unstable" inputs [
        "niri-flake"
        "packages"
        system
        "niri-unstable"
      ])
    )
    (final: prev: {
      # scoped overlays
      mc-config-nuc = inputs.mc-config-nuc.overlays.default final prev;
      lanzaboote = inputs.lanzaboote.overlays.default final prev;
    })
    (final: prev: {
      # TODO broken with auto-allocate-uids
      ccacheStdenv = final.stdenv;
      # # ccache
      # ccacheCacheDir = "/var/cache/ccache";
      # ccacheLogDir = "/var/log/ccache";
      # ccacheWrapper = prev.ccacheWrapper.override {
      #   extraConfig = ''
      #     export CCACHE_COMPRESS=1
      #     export CCACHE_UMASK=007
      #     if [ -d "${final.ccacheCacheDir}" ]; then
      #       export CCACHE_DIR="${final.ccacheCacheDir}"
      #     else
      #       export CCACHE_DIR="/tmp/ccache"
      #       mkdir -p "$CCACHE_DIR"
      #       echo "ccacheWrapper: \"${final.ccacheCacheDir}\" is not a directory, cache in \"$CCACHE_DIR\"" >&2
      #     fi
      #     if [ -d "${final.ccacheLogDir}" ]; then
      #       export CCACHE_LOGFILE="${final.ccacheLogDir}/ccache.log"
      #     fi
      #     if [ ! -w "$CCACHE_DIR" ]; then
      #       echo "ccacheWrapper: '$CCACHE_DIR' is not accessible for user $(whoami)" >&2
      #       exit 1
      #     fi
      #   '';
      # };
      # ccacheTest = final.ccacheStdenv.mkDerivation {
      #   name = "test-ccache";
      #   src = builtins.toFile "hello-world.c" ''
      #     #include <stdio.h>
      #     int main() { printf("hello, world\n"); }
      #   '';
      #   dontUnpack = true;
      #   env.NIX_DEBUG = 1;
      #   buildPhase = "cc $src -o hello";
      #   installPhase = "install -D hello $out/bin/hello";
      # };

      # adjustment
      nixVersions = prev.nixVersions // {
        selected = final.nixVersions.latest;
      };
      nix = final.nixVersions.selected;
      gnuradio = prev.gnuradio.override {
        unwrapped = prev.gnuradio.unwrapped.override {
          stdenv = final.ccacheStdenv;
          soapysdr = final.soapysdr-with-plugins;
        };
      };
      zerotierone = prev.zerotierone.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/zerotierone-increase-world-max-roots.patch ];
      });
      tailscale = prev.tailscale.overrideAttrs (old: {
        subPackages = old.subPackages ++ [ "cmd/derper" ];
      });
      tailscale-derp = final.tailscale;
      waydroid = prev.waydroid.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/waydroid-mount-nix-and-run-binfmt.patch ];
      });
      gnome-shell = (prev.gnome-shell.override { stdenv = final.ccacheStdenv; }).overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/gnome-shell-preedit-fix.patch ];
      });
      mutter =
        assert (lib.versions.major prev.mutter.version == "46");
        (prev.mutter.override { stdenv = final.ccacheStdenv; }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            # git format-patch (git merge-base origin/gnome-$MV ubuntu/triple-buffering-$PV-$MV)..ubuntu/triple-buffering-$PV-$MV --stdout
            ../patches/mutter-triple-buffering.patch
            ../patches/mutter-text-input-v1.patch
          ];
        });
      linuxManualConfig = prev.linuxManualConfig.override { stdenv = final.ccacheStdenv; };
      blender = prev.blender.override {
        cudaSupport = true;
      };
    })
  ];
  alternativeChannels = nixpkgsArgs: {
    latest = import inputs.nixpkgs-latest nixpkgsArgs;
    unstable-small = import inputs.nixpkgs-unstable-small nixpkgsArgs;
    stable = import inputs.nixpkgs-stable nixpkgsArgs;
  };
  earlyFixes =
    nixpkgsArgs:
    let
      # deadnix: skip
      inherit (alternativeChannels nixpkgsArgs) latest unstable-small stable;
    in
    [ (_final: _prev: { }) ];
  lateFixes =
    nixpkgsArgs:
    let
      # deadnix: skip
      inherit (alternativeChannels nixpkgsArgs) latest unstable-small stable;
    in
    [
      (
        _final: _prev:
        {
        }
      )
    ];
in
{
  perSystem =
    { config, system, ... }:
    lib.mkMerge [
      # common nixpkgs options
      {
        nixpkgs = {
          config = {
            allowUnfree = true;
            # TODO wait for mautrix-telegram update
            # TODO wait for matrix-qq update
            # TODO wait for logseq update
            allowInsecurePredicate =
              p:
              (p.pname or null) == "olm"
              || (
                (p.pname or null) == "electron"
                && lib.elem (lib.versions.major (p.version or null)) [
                  "27"
                  "28"
                ]
              ); # for dependency of logseq
          };
          overlays =
            let
              # do not include overlays to prevent infinite recursion
              overlayNixpkgsArgs = {
                inherit (config.nixpkgs)
                  localSystem
                  crossSystem
                  config
                  crossOverlays
                  ;
              };
            in
            (earlyFixes overlayNixpkgsArgs) ++ packages ++ (lateFixes overlayNixpkgsArgs);
        };
      }
      (lib.mkIf (system == "riscv64-linux") {
        # cross from x86_64-linux
        nixpkgs.path = inputs.nixpkgs-riscv;
        nixpkgs.localSystem = {
          system = "x86_64-linux";
        };
        nixpkgs.crossSystem = {
          inherit system;
        };
      })
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
}
