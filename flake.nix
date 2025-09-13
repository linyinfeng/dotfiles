{
  description = "A highly structured configuration database.";

  inputs = {
    # flake-parts

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # nixpkgs

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-latest.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-riscv.url = "github:nickcao/nixpkgs/riscv";

    # flake modules

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore-nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks-nix.inputs.gitignore.follows = "gitignore-nix";
    git-hooks-nix.inputs.flake-compat.follows = "flake-compat";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.flake-compat.follows = "flake-compat";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";

    flat-flake.url = "github:linyinfeng/flat-flake";
    flat-flake.inputs.crane.follows = "crane";
    flat-flake.inputs.flake-compat.follows = "flake-compat";
    flat-flake.inputs.flake-parts.follows = "flake-parts";
    flat-flake.inputs.nixpkgs.follows = "nixpkgs";
    flat-flake.inputs.rust-overlay.follows = "rust-overlay";
    flat-flake.inputs.systems.follows = "systems";
    flat-flake.inputs.treefmt-nix.follows = "treefmt-nix";

    # nixos modules

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:linyinfeng/lanzaboote/uki";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.inputs.crane.follows = "crane";
    lanzaboote.inputs.rust-overlay.follows = "rust-overlay";
    lanzaboote.inputs.flake-compat.follows = "flake-compat";
    lanzaboote.inputs.flake-parts.follows = "flake-parts";
    lanzaboote.inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixlib.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.devshell.follows = "devshell";
    nix-topology.inputs.flake-utils.follows = "flake-utils";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
    nix-topology.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";

    kukui-nixos.url = "github:linyinfeng/kukui-nixos";
    kukui-nixos.inputs.nixpkgs.follows = "nixpkgs";
    kukui-nixos.inputs.conf2nix.follows = "conf2nix";
    kukui-nixos.inputs.crane.follows = "crane";
    kukui-nixos.inputs.disko.follows = "disko";
    kukui-nixos.inputs.flake-compat.follows = "flake-compat";
    kukui-nixos.inputs.flake-parts.follows = "flake-parts";
    kukui-nixos.inputs.treefmt-nix.follows = "treefmt-nix";
    kukui-nixos.inputs.pmaports.follows = "pmaports";

    # home-manager modules

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.nixpkgs-stable.follows = "blank";

    nixos-vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-vscode-server.inputs.flake-utils.follows = "flake-utils";
    nixos-vscode-server.inputs.nixpkgs.follows = "nixpkgs";

    # programs

    nix-gc-s3.url = "github:linyinfeng/nix-gc-s3";
    nix-gc-s3.inputs.nixpkgs.follows = "nixpkgs";
    nix-gc-s3.inputs.flake-parts.follows = "flake-parts";
    nix-gc-s3.inputs.flake-utils.follows = "flake-utils";
    nix-gc-s3.inputs.poetry2nix.follows = "poetry2nix";
    nix-gc-s3.inputs.treefmt-nix.follows = "treefmt-nix";
    nix-gc-s3.inputs.devshell.follows = "devshell";
    nix-gc-s3.inputs.blank.follows = "blank";
    nix-gc-s3.inputs.systems.follows = "systems";

    angrr.url = "github:linyinfeng/angrr";
    angrr.inputs.nixpkgs.follows = "nixpkgs";
    angrr.inputs.flake-compat.follows = "flake-compat";
    angrr.inputs.flake-parts.follows = "flake-parts";
    angrr.inputs.treefmt-nix.follows = "treefmt-nix";

    pastebin.url = "github:linyinfeng/pastebin";
    pastebin.inputs.nixpkgs.follows = "nixpkgs";
    pastebin.inputs.flake-parts.follows = "flake-parts";
    pastebin.inputs.treefmt-nix.follows = "treefmt-nix";

    oranc.url = "github:linyinfeng/oranc";
    oranc.inputs.crane.follows = "crane";
    oranc.inputs.flake-compat.follows = "flake-compat";
    oranc.inputs.flake-parts.follows = "flake-parts";
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

    cachix.url = "github:cachix/cachix/latest";
    cachix.inputs.nixpkgs.follows = "nixpkgs";
    cachix.inputs.devenv.follows = "blank";
    cachix.inputs.flake-compat.follows = "flake-compat";
    cachix.inputs.git-hooks.follows = "git-hooks-nix";

    commit-notifier.url = "github:linyinfeng/commit-notifier";
    commit-notifier.inputs.crane.follows = "crane";
    commit-notifier.inputs.flake-parts.follows = "flake-parts";
    commit-notifier.inputs.flake-utils.follows = "flake-utils";
    commit-notifier.inputs.systems.follows = "systems";
    commit-notifier.inputs.rust-overlay.follows = "rust-overlay";
    commit-notifier.inputs.nixpkgs.follows = "nixpkgs";
    commit-notifier.inputs.treefmt-nix.follows = "treefmt-nix";

    mc-config-nuc.url = "github:linyinfeng/mc-config-nuc";
    mc-config-nuc.inputs.nixpkgs.follows = "nixpkgs";
    mc-config-nuc.inputs.flake-parts.follows = "flake-parts";
    mc-config-nuc.inputs.flake-utils.follows = "flake-utils";
    mc-config-nuc.inputs.mc-config.follows = "mc-config";
    mc-config-nuc.inputs.treefmt-nix.follows = "treefmt-nix";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    niri-flake.inputs.niri-stable.follows = "blank";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixpkgs";
    nvfetcher.inputs.flake-utils.follows = "flake-utils";
    nvfetcher.inputs.flake-compat.follows = "flake-compat";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.flake-compat.follows = "flake-compat";
    nix-alien.inputs.nix-index-database.follows = "nix-index-database";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";

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

    lantian.url = "github:xddxdd/nur-packages";
    lantian.inputs.nixpkgs.follows = "nixpkgs";
    lantian.inputs.nixpkgs-24_05.follows = "nixpkgs";
    lantian.inputs.flake-parts.follows = "flake-parts";
    lantian.inputs.nvfetcher.follows = "nvfetcher";
    lantian.inputs.nix-index-database.follows = "nix-index-database";
    lantian.inputs.treefmt-nix.follows = "treefmt-nix";
    lantian.inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks-nix";
    lantian.inputs.devshell.follows = "devshell";

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.flake-compat.follows = "flake-compat";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

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

    crane.url = "github:ipetkov/crane";

    crate2nix.url = "github:nix-community/crate2nix";
    crate2nix.inputs.nixpkgs.follows = "nixpkgs";
    crate2nix.inputs.flake-parts.follows = "flake-parts";
    crate2nix.inputs.flake-compat.follows = "flake-compat";
    crate2nix.inputs.devshell.follows = "devshell";
    crate2nix.inputs.crate2nix_stable.follows = "blank";
    crate2nix.inputs.nix-test-runner.follows = "blank";
    crate2nix.inputs.cachix.follows = "cachix";
    crate2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    naersk.inputs.fenix.follows = "fenix";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    gitignore-nix.url = "github:hercules-ci/gitignore.nix";
    gitignore-nix.inputs.nixpkgs.follows = "nixpkgs";

    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.inputs.flake-utils.follows = "flake-utils";
    poetry2nix.inputs.nix-github-actions.follows = "nix-github-actions";
    poetry2nix.inputs.systems.follows = "systems";
    poetry2nix.inputs.treefmt-nix.follows = "treefmt-nix";

    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";

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

    nix-filter.url = "github:numtide/nix-filter";

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

    flake-schemas.url = "github:determinatesystems/flake-schemas";

    weird-deployer.url = "github:linyinfeng/weird-deployer";

    conf2nix.url = "github:linyinfeng/conf2nix";
    conf2nix.inputs.nixpkgs.follows = "nixpkgs";
    conf2nix.inputs.flake-parts.follows = "flake-parts";
    conf2nix.inputs.crane.follows = "crane";
    conf2nix.inputs.flake-compat.follows = "flake-compat";
    conf2nix.inputs.treefmt-nix.follows = "treefmt-nix";

    # compatibility layer

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # other

    mobile-nixos.url = "github:linyinfeng/mobile-nixos/development";
    mobile-nixos.flake = false;

    pmaports.url = "gitlab:postmarketOS/pmaports?host=gitlab.postmarketos.org";
    pmaports.flake = false;

    # fixes

    nixpkgs-sd-switch.url = "github:nixos/nixpkgs/pull/442482/head";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, lib, ... }:
      let
        selfLib = import ./lib { inherit inputs lib; };
      in
      {
        flatFlake.config = {
          allowed = [
            [
              "fenix"
              "rust-analyzer-src"
            ]
            [
              "niri-flake"
              "niri-unstable"
            ]
            [
              "niri-flake"
              "xwayland-satellite-unstable"
            ]
            [
              "niri-flake"
              "xwayland-satellite-stable"
            ]
            [
              "kukui-nixos"
              "nixpkgs-alsa-ucm-conf"
            ]
          ];
        };
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "riscv64-linux"
          "loongarch64-linux"
        ];
        devSystems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake.lib = selfLib // {
          inherit (config) systems;
        };
        imports = [
          inputs.flat-flake.flakeModules.flatFlake
          inputs.flake-parts.flakeModules.easyOverlay
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.pre-commit-hooks-nix.flakeModule
          inputs.linyinfeng.flakeModules.nixpkgs
          inputs.linyinfeng.flakeModules.passthru
          inputs.linyinfeng.flakeModules.nixago
          inputs.nix-topology.flakeModule
        ]
        ++ selfLib.buildModuleList ./flake;
      }
    );
}
