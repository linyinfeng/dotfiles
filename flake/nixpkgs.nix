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
      blender = prev.blender.override {
        cudaSupport = true;
      };
    })
  ];
  alternativeChannels = nixpkgsArgs: {
    unstable = import inputs.nixpkgs nixpkgsArgs;
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
      (_final: prev: {
        # TODO wait for https://nixpkgs-tracker.ocfox.me/?pr=
        # TODO not working with selected nix
        inherit (unstable-small) nixd;
        # TODO wait for https://github.com/c0fec0de/anytree/issues/270
        # TODO wait for https://github.com/NixOS/nixpkgs/issues/375763
        python3Packages = prev.python3Packages.overrideScope (
          _finalPy: prevPy: {
            anytree = prevPy.anytree.overrideAttrs (old: {
              patches = old.patches ++ [ ../patches/python-anytree-poetry-project-name-version.patch ];
            });
          }
        );
      })
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
            # TODO wait for mautrix-telegram, matrix-qq, and logseq update
            allowInsecurePredicate =
              p:
              (p.pname or null) == "olm"
              || (
                (p.pname or null) == "electron"
                && lib.elem (lib.versions.major (p.version or null)) [
                  "27"
                  "28"
                ]
              );
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
