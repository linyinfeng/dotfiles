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
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        hydra-master = inputs'.hydra.packages.default;
      })
  ];

  fixes = final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
    inherit ((getSystem system).allModuleArgs) inputs';
  in {
    # TODO upstream
    gnuradio = prev.gnuradio.override {
      unwrapped = prev.gnuradio.unwrapped.override {
        soapysdr = final.soapysdr-with-plugins;
      };
    };

    # TODO upstream
    tailscale-derp = final.tailscale.overrideAttrs (old: {
      subPackages =
        old.subPackages
        ++ [
          "cmd/derper"
        ];
    });

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=221434
    mautrix-telegram = prev.mautrix-telegram.overrideAttrs (old: {
      propagatedBuildInputs =
        old.propagatedBuildInputs
        or []
        ++ [
          final.python3.pkgs.setuptools
        ];
    });

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=220317
    inherit
      (inputs'.nixpkgs-matrix-sdk-crypto-nodejs.legacyPackages)
      matrix-sdk-crypto-nodejs
      ;

    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=219315
    inherit
      (inputs'.nixpkgs-rime-data.legacyPackages)
      fcitx5-with-addons
      ibus-with-plugins
      ;
    ibus-engines =
      prev.ibus-engines
      // {
        inherit (inputs'.nixpkgs-rime-data.legacyPackages.ibus-engines) rime;
      };

    # TODO wait for htt
    inherit (inputs'.nixpkgs-mastodon.legacyPackages) mastodon;
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
