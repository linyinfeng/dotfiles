{
  inputs,
  withSystem,
  ...
}: let
  packages = [
    inputs.sops-nix.overlay
    inputs.nixos-cn.overlay
    inputs.linyinfeng.overlays.singleRepoNur
    inputs.emacs-overlay.overlay
    (final: prev: let
      system = final.stdenv.hostPlatform.system;
    in {
      nixVersions =
        prev.nixVersions.extend
        (final': prev': {
          master = inputs.nix.packages.${system}.nix;
          selected = final'.unstable;
        });
      hydra-master =
        if system == "x86_64-linux"
        then inputs.hydra.packages.${system}.default
        else null;
      nix-gc-s3 = inputs.nix-gc-s3.packages.${system}.nix-gc-s3;
      pastebin = inputs.pastebin.packages.${system}.default;
      mc-config-nuc = inputs.mc-config-nuc.packages.${system};
      nix-index-database =
        if system == "x86_64-linux"
        then inputs.nix-index-database.legacyPackages.${system}.database
        else null;
    })
  ];

  fixes = final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
  in
    withSystem system ({inputs', ...}: {
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
    });
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
