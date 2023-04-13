{
  description = "A highly structured configuration database.";

  inputs = {
    # flake-parts

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # nixpkgs

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    latest.url = "github:nixos/nixpkgs/master";

    # flake modules

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.flake-utils.follows = "flake-utils";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks-nix.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore-nix";

    # nixos modules

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.utils.follows = "flake-utils";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    hydra.url = "github:nixos/hydra";
    # hydra.inputs.nix.follows = "nix";
    # hydra.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.rust-overlay.follows = "rust-overlay";
    lanzaboote.inputs.flake-compat.follows = "flake-compat";
    lanzaboote.inputs.flake-utils.follows = "flake-utils";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
    # TODO wait for https://github.com/ipetkov/crane/issues/262
    # lanzaboote.inputs.crane.follows = "crane";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixlib.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    # home-manager modules

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.flake-utils.follows = "flake-utils";

    # programs

    nix-gc-s3.url = "github:linyinfeng/nix-gc-s3";
    nix-gc-s3.inputs.nixpkgs.follows = "nixpkgs";
    nix-gc-s3.inputs.flake-utils-plus.follows = "flake-utils-plus";
    nix-gc-s3.inputs.poetry2nix.follows = "poetry2nix";

    pastebin.url = "github:linyinfeng/pastebin";
    pastebin.inputs.nixpkgs.follows = "nixpkgs";
    pastebin.inputs.flake-utils-plus.follows = "flake-utils-plus";

    attic.url = "github:zhaofengli/attic";
    attic.inputs.crane.follows = "crane";
    attic.inputs.flake-compat.follows = "flake-compat";
    attic.inputs.flake-utils.follows = "flake-utils";
    attic.inputs.nixpkgs.follows = "nixpkgs";
    attic.inputs.nixpkgs-stable.follows = "nixpkgs";

    oranc.url = "github:linyinfeng/oranc";
    oranc.inputs.crane.follows = "crane";
    oranc.inputs.flake-compat.follows = "flake-compat";
    oranc.inputs.flake-parts.follows = "flake-parts";
    oranc.inputs.flake-utils.follows = "flake-utils";
    oranc.inputs.rust-overlay.follows = "rust-overlay";
    oranc.inputs.nixpkgs.follows = "nixpkgs";
    oranc.inputs.treefmt-nix.follows = "treefmt-nix";

    ace-bot.url = "github:linyinfeng/ace-bot";
    ace-bot.inputs.crane.follows = "crane";
    ace-bot.inputs.flake-compat.follows = "flake-compat";
    ace-bot.inputs.flake-parts.follows = "flake-parts";
    ace-bot.inputs.flake-utils.follows = "flake-utils";
    ace-bot.inputs.rust-overlay.follows = "rust-overlay";
    ace-bot.inputs.nixpkgs.follows = "nixpkgs";
    ace-bot.inputs.treefmt-nix.follows = "treefmt-nix";

    mc-config-nuc.url = "github:linyinfeng/mc-config-nuc";
    mc-config-nuc.inputs.nixpkgs.follows = "nixpkgs";
    mc-config-nuc.inputs.flake-utils-plus.follows = "flake-utils-plus";
    mc-config-nuc.inputs.mc-config.follows = "mc-config";
    mc-config-nuc.inputs.minecraft-nix.follows = "minecraft-nix";
    mc-config-nuc.inputs.minecraft-json.follows = "minecraft-json";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    # combined flakes

    linyinfeng.url = "github:linyinfeng/nur-packages";
    linyinfeng.inputs.flake-parts.follows = "flake-parts";
    linyinfeng.inputs.flake-utils.follows = "flake-utils";
    linyinfeng.inputs.nixpkgs.follows = "nixpkgs";
    linyinfeng.inputs.nixos-stable.follows = "blank";
    linyinfeng.inputs.devshell.follows = "devshell";
    linyinfeng.inputs.treefmt-nix.follows = "treefmt-nix";

    nixos-cn.url = "github:nixos-cn/flakes";
    nixos-cn.inputs.nixpkgs.follows = "nixpkgs";
    nixos-cn.inputs.flake-utils.follows = "flake-utils";

    # libraries

    blank.url = "github:divnix/blank";

    flake-utils.url = "github:numtide/flake-utils";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    digga.url = "github:divnix/digga";
    digga.inputs.nixlib.follows = "nixpkgs";
    digga.inputs.nixpkgs.follows = "nixpkgs";
    digga.inputs.nixpkgs-unstable.follows = "nixpkgs";
    digga.inputs.darwin.follows = "blank";
    digga.inputs.home-manager.follows = "home-manager";
    digga.inputs.deploy.follows = "blank";
    digga.inputs.flake-compat.follows = "flake-compat";
    digga.inputs.devshell.follows = "devshell";
    digga.inputs.flake-utils-plus.follows = "flake-utils-plus";
    digga.inputs.flake-utils.follows = "flake-utils";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";

    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    crane.inputs.rust-overlay.follows = "rust-overlay";
    crane.inputs.flake-utils.follows = "flake-utils";
    crane.inputs.flake-compat.follows = "flake-compat";

    gitignore-nix.url = "github:hercules-ci/gitignore.nix";
    gitignore-nix.inputs.nixpkgs.follows = "nixpkgs";

    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.inputs.flake-utils.follows = "flake-utils";

    mc-config.url = "github:linyinfeng/mc-config";
    mc-config.inputs.nixpkgs.follows = "nixpkgs";
    mc-config.inputs.flake-utils-plus.follows = "flake-utils-plus";
    mc-config.inputs.minecraft-nix.follows = "minecraft-nix";
    mc-config.inputs.minecraft-json.follows = "minecraft-json";

    minecraft-nix.url = "github:ninlives/minecraft.nix";
    minecraft-nix.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-nix.inputs.flake-utils.follows = "flake-utils";
    minecraft-nix.inputs.metadata.follows = "minecraft-json";

    minecraft-json.url = "github:ninlives/minecraft.json";
    minecraft-json.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-json.inputs.flake-utils.follows = "flake-utils";

    nixago.url = "github:nix-community/nixago";
    nixago.inputs.nixpkgs.follows = "nixpkgs";
    nixago.inputs.flake-utils.follows = "flake-utils";

    # compatibility layer

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # patches
    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=220317
    nixpkgs-matrix-sdk-crypto-nodejs.url = "github:nixos/nixpkgs/pull/220317/head";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;}
    ({
      self,
      lib,
      ...
    }: let
      selfLib = import ./lib {inherit inputs lib;};
    in {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      flake.lib = selfLib;
      imports =
        [
          inputs.flake-parts.flakeModules.easyOverlay
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.pre-commit-hooks-nix.flakeModule
          inputs.linyinfeng.flakeModules.nixpkgs
          inputs.linyinfeng.flakeModules.passthru
          inputs.linyinfeng.flakeModules.nixago
        ]
        ++ selfLib.buildModuleList ./flake;
    });
}
