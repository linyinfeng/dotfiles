{ lib, ... }:

{
  perSystem =
    { system, pkgs, ... }:
    let
      skipped = pkgs.runCommand "skipped-check" { } "touch $out";
    in
    lib.mkMerge [
      # only check source code on x86_64-linux
      (lib.mkIf (system != "x86_64-linux") {
        checks.flat-flake = lib.mkForce skipped;
        checks.pre-commit = lib.mkForce skipped;
        checks.treefmt = lib.mkForce skipped;
      })

      # only check develop environment on x86_64-linux and aarch64-linux
      (lib.mkIf (
        !lib.elem system [
          "x86_64-linux"
          "aarch64-linux"
        ]
      ) { checks."devShells/default" = lib.mkForce skipped; })
    ];
}
