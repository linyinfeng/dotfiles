{
  inputs,
  getSystem,
  lib,
  ...
}: let
  packages = [
    inputs.sops-nix.overlays.default
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.singleRepoNur
    inputs.attic.overlays.default
    inputs.oranc.overlays.default
    inputs.ace-bot.overlays.default
    inputs.emacs-overlay.overlay
    inputs.hyprland.overlays.default
    inputs.hyprwm-contrib.overlays.default
    (final: prev: let
      inherit (prev.stdenv.hostPlatform) system;
      inherit ((getSystem system).allModuleArgs) inputs';
    in
      {
        nixVersions =
          prev.nixVersions.extend
          (final': prev': {
            master = inputs'.nix.packages.nix;
            selected = final'.unstable;
          });
        nix-gc-s3 = inputs'.nix-gc-s3.packages.nix-gc-s3;
        pastebin = inputs'.pastebin.packages.default;
        mc-config-nuc = inputs'.mc-config-nuc.packages;
        nix-index-with-db = inputs'.nix-index-database.packages.nix-index-with-db;
        comma = prev.comma.override {
          nix-index-unwrapped = final.nix-index-with-db;
        };
        gnuradio = prev.gnuradio.override {
          unwrapped = prev.gnuradio.unwrapped.override {
            soapysdr = final.soapysdr-with-plugins;
          };
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        hydra-master = inputs'.hydra.packages.default;
      })
  ];

  fixes = final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
    inherit ((getSystem system).allModuleArgs) inputs';
  in {
    # use waybar-git
    waybar = prev.waybar.overrideAttrs (old: {
      inherit (final.nur.repos.linyinfeng.sources.waybar-git) version src;
    });

    # TODO upstream
    tailscale-derp = final.tailscale.overrideAttrs (old: {
      subPackages =
        old.subPackages
        ++ [
          "cmd/derper"
        ];
    });

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=226427
    inherit (inputs'.nixpkgs-wluma.legacyPackages) wluma;

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=226283
    inherit (inputs'.nixpkgs-wayland.legacyPackages) wayland;
    hyprland = prev.hyprland.override {
      hidpiXWayland = true;
    };
  };
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays =
      packages
      ++ [
        fixes
      ];
  };
}
