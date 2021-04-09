{
  description = "A highly structured configuration database.";

  inputs =
    {
      nixos.url = "github:nixos/nixpkgs/nixos-unstable";
      nixos-20_09.url = "github:nixos/nixpkgs/nixos-20.09";
      override.url = "github:nixos/nixpkgs";
      nur.url = "github:nix-community/nur";
      ci-agent = {
        url = "github:hercules-ci/hercules-ci-agent";
        inputs = { nix-darwin.follows = "darwin"; flake-compat.follows = "flake-compat"; nixos-20_09.follows = "nixos-20_09"; nixos-unstable.follows = "nixos"; };
      };
      darwin.url = "github:LnL7/nix-darwin";
      darwin.inputs.nixpkgs.follows = "nixos";
      deploy = {
        url = "github:serokell/deploy-rs";
        inputs = { flake-compat.follows = "flake-compat"; naersk.follows = "naersk"; nixpkgs.follows = "nixos"; utils.follows = "utils"; };
      };
      devshell.url = "github:numtide/devshell";
      flake-compat.url = "github:BBBSnowball/flake-compat/pr-1";
      flake-compat.flake = false;
      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
      naersk.url = "github:nmattia/naersk";
      naersk.inputs.nixpkgs.follows = "nixos";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      utils.url = "github:numtide/flake-utils";
      pkgs.url = "path:./pkgs";
      pkgs.inputs.nixpkgs.follows = "nixos";

      impermanence.url = "github:nix-community/impermanence";
      emacs-overlay.url = "github:nix-community/emacs-overlay";
      nixops = {
        url = "github:nixos/nixops";
        inputs = { nixpkgs.follows = "nixos"; utils.follows = "utils"; };
      };
    };

  outputs = inputs@{ deploy, nixos, nur, self, utils, ... }:
    let
      lib = import ./lib { inherit self nixos inputs; };
    in
    lib.mkFlake
      {
        inherit self;
        hosts = ./hosts;
        packages = import ./pkgs;
        suites = import ./suites;
        extern = import ./extern;
        overrides = import ./overrides;
        overlays = ./overlays;
        profiles = ./profiles;
        userProfiles = ./users/profiles;
        modules = import ./modules/module-list.nix;
        userModules = import ./users/modules/module-list.nix;
      } // {
      inherit lib;
      defaultTemplate = self.templates.flk;
      templates.flk.path = ./.;
      templates.flk.description = "flk template";
    };
}
