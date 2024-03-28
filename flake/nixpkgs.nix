{
  inputs,
  getSystem,
  lib,
  ...
}:
let
  packages = [
    (
      final: prev:
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
    inputs.hyprland.overlays.default
    inputs.hyprwm-contrib.overlays.default
    inputs.flat-flake.overlays.default
    inputs.deploy-rs.overlay
    inputs.nix-index-database.overlays.nix-index
    (
      final: prev:
      let
        inherit (prev.stdenv.hostPlatform) system;
        inherit ((getSystem system).allModuleArgs) inputs';
      in
      {
        mc-config-nuc = inputs.mc-config-nuc.overlays.default final prev;
        lanzaboote = inputs.lanzaboote.overlays.default final prev;
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
  earlyFixes = nixpkgsArgs: final: prev: {
    # currently nothing
  };

  lateFixes =
    nixpkgsArgs: final: prev:
    let
      latest = import inputs.latest nixpkgsArgs;
    in
    {
      inherit (import inputs.nixpkgs-terraform nixpkgsArgs) terraform;
      inherit (import inputs.nixpkgs-shim nixpkgsArgs) shim-unsigned;
    };
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
            # TODO wait for zotero 7
            allowInsecurePredicate =
              p: (p.pname or null) == "zotero" && lib.versions.major (p.version or null) == "6";
          };
          overlays =
            let
              # do not include overlays to prevent infinite recursion
              overlayNixpkgsArgs = lib.attrsets.removeAttrs config.nixpkgs [ "overlays" ];
            in
            [ (earlyFixes overlayNixpkgsArgs) ] ++ packages ++ [ (lateFixes overlayNixpkgsArgs) ];
        };
      }
      (lib.mkIf (system == "riscv64-linux") {
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
