{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # ncro 2.4.0 links sqlite3 without declaring it, and the cargo setup hook now
  # forces the system copy instead of a vendored one
  ncro = inputs.ncro.packages.${pkgs.stdenv.hostPlatform.system}.ncro.overrideAttrs (prev: {
    buildInputs = (prev.buildInputs or [ ]) ++ [ pkgs.sqlite ];
  });
in
{
  imports = [ inputs.ncro.nixosModules.ncro ];

  services.ncro.package = lib.mkForce ncro;
}
