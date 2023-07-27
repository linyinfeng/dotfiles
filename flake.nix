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
    devshell.inputs.systems.follows = "systems";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks-nix.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.nixpkgs-stable.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore-nix";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.flake-compat.follows = "flake-compat";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    # nixos modules

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.flake-compat.follows = "flake-compat";
    lanzaboote.inputs.flake-utils.follows = "flake-utils";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixlib.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    # home-manager modules

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.flake-utils.follows = "flake-utils";
    emacs-overlay.inputs.nixpkgs-stable.follows = "blank";

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
    mc-config-nuc.inputs.flake-parts.follows = "flake-parts";
    mc-config-nuc.inputs.flake-utils.follows = "flake-utils";
    mc-config-nuc.inputs.mc-config.follows = "mc-config";
    mc-config-nuc.inputs.treefmt-nix.follows = "treefmt-nix";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    hyprwm-contrib.url = "github:hyprwm/contrib";
    hyprwm-contrib.inputs.nixpkgs.follows = "nixpkgs";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";
    nvfetcher.inputs.flake-utils.follows = "flake-utils";
    nvfetcher.inputs.flake-compat.follows = "flake-compat";

    # combined flakes

    linyinfeng.url = "github:linyinfeng/nur-packages";
    linyinfeng.inputs.flake-parts.follows = "flake-parts";
    linyinfeng.inputs.flake-utils.follows = "flake-utils";
    linyinfeng.inputs.nixpkgs.follows = "nixpkgs";
    linyinfeng.inputs.nixos-stable.follows = "blank";
    linyinfeng.inputs.devshell.follows = "devshell";
    linyinfeng.inputs.treefmt-nix.follows = "treefmt-nix";
    linyinfeng.inputs.nvfetcher.follows = "nvfetcher";
    linyinfeng.inputs.flake-compat.follows = "flake-compat";

    nixos-cn.url = "github:nixos-cn/flakes";
    nixos-cn.inputs.nixpkgs.follows = "nixpkgs";
    nixos-cn.inputs.flake-utils.follows = "flake-utils";

    # libraries

    blank.url = "github:divnix/blank";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    flake-utils-plus.inputs.flake-utils.follows = "flake-utils";

    haumea.url = "github:nix-community/haumea";
    haumea.inputs.nixpkgs.follows = "nixpkgs";

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

    systems.url = "github:nix-systems/default";

    mc-config.url = "github:linyinfeng/mc-config";
    mc-config.inputs.nixpkgs.follows = "nixpkgs";
    mc-config.inputs.flake-parts.follows = "flake-parts";
    mc-config.inputs.flake-utils.follows = "flake-utils";
    mc-config.inputs.minecraft-nix.follows = "minecraft-nix";
    mc-config.inputs.minecraft-json.follows = "minecraft-json";
    mc-config.inputs.systems.follows = "systems";
    mc-config.inputs.treefmt-nix.follows = "treefmt-nix";

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
    nixago.inputs.nixago-exts.follows = "nixago-exts";

    nixago-exts.url = "github:nix-community/nixago-extensions";
    nixago-exts.inputs.flake-utils.follows = "flake-utils";
    nixago-exts.inputs.nixago.follows = "nixago";
    nixago-exts.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # compatibility layer

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # other

    # TODO wait for https://github.com/NixOS/mobile-nixos/pull/627
    # mobile-nixos.url = "github:nixos/mobile-nixos";
    mobile-nixos.url = "github:linyinfeng/mobile-nixos/enchilada-staging";
    mobile-nixos.flake = false;

    # fixes
    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=242453
    nixpkgs-iproute2-ifd.url = "github:nixos/nixpkgs/pull/242453/head";
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
