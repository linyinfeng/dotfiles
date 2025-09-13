{
  self,
  inputs,
  lib,
  getSystem,
  ...
}:
let
  inherit (self.lib) requireBigParallel;
  packages = [
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
    inputs.nix-topology.overlays.default
    inputs.nix-alien.overlays.default
    inputs.kukui-nixos.overlays.default
    inputs.niri-flake.overlays.niri
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
      // (self.lib.maybeAttrByPath "lantian" inputs [
        "lantian"
        "packages"
        system
      ])
    )
    (final: prev: {
      # scoped overlays
      mc-config-nuc = inputs.mc-config-nuc.overlays.default final prev;
      lanzaboote = inputs.lanzaboote.overlays.default final prev;
      mobile-nixos = import "${inputs.mobile-nixos}/overlay/overlay.nix" final prev;
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
      blender = prev.blender.override {
        cudaSupport = true;
      };
      iosevka-yinfeng = requireBigParallel (
        final.iosevka.override {
          privateBuildPlan = {
            family = "Iosevka Yinfeng";
            spacing = "fontconfig-mono";
            serifs = "slab";
            ligations = {
              inherits = "haskell";
            };
          };
          set = "yinfeng";
        }
      );
      iosevka-yinfeng-nf = final.stdenv.mkDerivation {
        name = "iosevka-yinfeng-nf";
        src = final.iosevka-yinfeng;
        nativeBuildInputs = with final; [ nerd-font-patcher ];
        enableParallelBuilding = true;
        requiredSystemFeatures = [ "big-parallel" ];
        unpackPhase = ''
          mkdir -p fonts
          cp -r $src/share/fonts/truetype/. ./fonts/
          chmod u+w -R ./fonts
        '';
        postPatch = ''
          cp ${../nixos/profiles/graphical/fonts/_nerd-font/Makefile} ./Makefile
        '';
      };
      vscode = final.symlinkJoin {
        inherit (prev.vscode) pname version meta;
        paths = [ prev.vscode ];
        buildInputs = [ final.makeWrapper ];
        # TODO remove --password-store=gnome-libsecret
        # wait for https://github.com/microsoft/vscode/issues/187338
        postBuild = ''
          wrapProgram "$out/bin/code" \
            --add-flags --ozone-platform-hint=auto \
            --add-flags --enable-wayland-ime \
            --add-flags --wayland-text-input-version=3 \
            --add-flags --password-store=gnome-libsecret
        '';
      };
      qq = final.symlinkJoin {
        inherit (prev.qq) pname version meta;
        paths = [ prev.qq ];
        buildInputs = [ final.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/qq" \
            --add-flags --enable-wayland-ime \
            --add-flags --wayland-text-input-version=3
        '';
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
    [
      (_final: _prev: {
        # maintained packages
        inherit (latest) godns;
      })
    ];
  lateFixes =
    nixpkgsArgs:
    let
      # deadnix: skip
      inherit (alternativeChannels nixpkgsArgs) latest unstable-small stable;
    in
    [
      (_final: prev: {
        # TODO remove
        tailscale = prev.tailscale.overrideAttrs (_: {
          doCheck = false;
        });
        inherit (import inputs.nixpkgs-sd-switch nixpkgsArgs) sd-switch;
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
            # cudaSupport = true;
            # rocmSupport = true;
            # TODO wait for mautrix-telegram, matrix-qq
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

  # special checks
  flake.checks = {
    "x86_64-linux" =
      let
        inherit ((getSystem "x86_64-linux").allModuleArgs) pkgs;
      in
      {
        "package/iosevka-yinfeng" = pkgs.iosevka-yinfeng;
        "package/iosevka-yinfeng-nf" = pkgs.iosevka-yinfeng-nf;
        "package/blender" = pkgs.blender;
        "package/gnuradio" = pkgs.gnuradio;
      };
  };
}
