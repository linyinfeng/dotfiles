{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
  };
  outputs =
    inputs@{ self, nixpkgs, flake-utils-plus }:
    flake-utils-plus.lib.mkFlake {
      inherit self inputs;

      outputsBuilder = channels:
        let
          pkgs = channels.nixpkgs;
        in
        {
          devShell = pkgs.mkShell {
            packages = with pkgs; [
              fup-repl
            ];
          };
        };
    };
}
