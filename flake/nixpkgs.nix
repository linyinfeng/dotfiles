{
  config,
  inputs,
  getSystem,
  lib,
  ...
}:
let
  packages = [
    inputs.sops-nix.overlays.default
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.singleRepoNur
    inputs.oranc.overlays.default
    inputs.ace-bot.overlays.default
    inputs.commit-notifier.overlays.default
    inputs.angrr.overlays.default
    inputs.emacs-overlay.overlay
    inputs.hyprland.overlays.default
    inputs.hyprwm-contrib.overlays.default
    inputs.flat-flake.overlays.default
    (
      final: prev:
      let
        inherit (prev.stdenv.hostPlatform) system;
        inherit ((getSystem system).allModuleArgs) inputs';
      in
      {
        nix-gc-s3 = inputs'.nix-gc-s3.packages.nix-gc-s3;
        pastebin = inputs'.pastebin.packages.default;
        mc-config-nuc = inputs'.mc-config-nuc.packages;
        nix-index-with-db = inputs'.nix-index-database.packages.nix-index-with-db;
        lzbt = inputs'.lanzaboote.packages.tool;
        nix-fast-build = inputs'.nix-fast-build.packages.default;

        # ccache
        ccacheCacheDir = "/var/cache/ccache";
        ccacheLogDir = "/var/log/ccache";
        ccacheWrapper = prev.ccacheWrapper.override {
          extraConfig = ''
            export CCACHE_COMPRESS=1
            export CCACHE_UMASK=007
            if [ -d "${final.ccacheCacheDir}" ]; then
              export CCACHE_DIR="${final.ccacheCacheDir}"
            else
              export CCACHE_DIR="/tmp/ccache"
              mkdir -p "$CCACHE_DIR"
              echo "ccacheWrapper: \"${final.ccacheCacheDir}\" is not a directory, cache in \"$CCACHE_DIR\"" >&2
            fi
            if [ -d "${final.ccacheLogDir}" ]; then
              export CCACHE_LOGFILE="${final.ccacheLogDir}/ccache.log"
            fi
            if [ ! -w "$CCACHE_DIR" ]; then
              echo "ccacheWrapper: '$CCACHE_DIR' is not accessible for user $(whoami)" >&2
              exit 1
            fi
          '';
        };
        ccacheTest = final.ccacheStdenv.mkDerivation {
          name = "test-ccache";
          src = builtins.toFile "hello-world.c" ''
            #include <stdio.h>
            int main() { printf("hello, world\n"); }
          '';
          dontUnpack = true;
          env.NIX_DEBUG = 1;
          buildPhase = "cc $src -o hello";
          installPhase = "install -D hello $out/bin/hello";
        };

        # adjustment
        comma = prev.comma.override { nix-index-unwrapped = final.nix-index-with-db; };
        gnuradio = prev.gnuradio.override {
          unwrapped = prev.gnuradio.unwrapped.override {
            stdenv = final.ccacheStdenv;
            soapysdr = final.soapysdr-with-plugins;
          };
        };
        zerotierone = prev.zerotierone.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../patches/zerotierone-debug-moon.patch ];
          buildFlags = (old.buildFlags or [ ]) ++ [ "ZT_DEBUG=1" ];
        });
        tailscale = prev.tailscale.overrideAttrs (old: {
          subPackages = old.subPackages ++ [ "cmd/derper" ];
          patches = (old.patches or [ ]) ++ [ ../patches/tailscale-excluded-interface-prefixes.patch ];
        });
        tailscale-derp = final.tailscale;
        waydroid = prev.waydroid.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../patches/waydroid-mount-nix-and-run-binfmt.patch ];
        });
        gnome =
          if (lib.versions.major prev.gnome.mutter.version == "45") then
            prev.gnome.overrideScope (
              gnomeFinal: gnomePrev: {
                mutter = (gnomePrev.mutter.override { stdenv = final.ccacheStdenv; }).overrideAttrs (old: {
                  patches = (old.patches or [ ]) ++ [
                    # git format-patch (git merge-base origin/gnome-MV ubuntu/triple-buffering-PV-MV)..ubuntu/triple-buffering-PV-MV --stdout
                    ../patches/mutter-triple-buffering.patch
                  ];
                });
              }
            )
          else
            prev.gnome;
        librime = inputs'.lantian.packages.lantianCustomized.librime-with-plugins;
      }
    )
  ];
  earlyFixes =
    final: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      inherit ((getSystem system).allModuleArgs) inputs';
    in
    {
      # currently nothing
    };

  lateFixes =
    final: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      inherit ((getSystem system).allModuleArgs) inputs';
      nixpkgsArgs = {
        inherit system;
        inherit (config.nixpkgs) config;
      };
      latest = import inputs.latest nixpkgsArgs;
    in
    {
      inherit (import inputs.nixpkgs-terraform nixpkgsArgs) terraform;
      inherit (import inputs.nixpkgs-shim nixpkgsArgs) shim-unsigned;
    };
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      # TODO wait for zotero 7
      allowInsecurePredicate =
        p: (p.pname or null) == "zotero" && lib.versions.major (p.version or null) == "6";
    };
    overlays = [ earlyFixes ] ++ packages ++ [ lateFixes ];
  };
}
