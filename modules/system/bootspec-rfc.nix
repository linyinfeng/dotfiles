# TODO wait for https://nixpk.gs/pr-tracker.html?pr=185116
{ inputs, config, lib, pkgs, ... }:

{
  # bootspec-rfc
  imports = [
    "${inputs.bootspec-rfc}/nixos/modules/system/boot/loader/external/external.nix"
    "${inputs.bootspec-rfc}/nixos/modules/system/activation/bootspec.nix"
  ];
  system.extraSystemBuilderCmds = ''
    ${lib.optionalString (!config.boot.isContainer) ''
      ${config.boot.bootspec.writer}
      ${config.boot.bootspec.validator} "$out/bootspec/${config.boot.bootspec.filename}"
    ''}
  '';
  nixpkgs.overlays = [
    (final: prev:
      let system = final.stdenv.hostPlatform.system; in {
        inherit (inputs.bootspec-rfc.legacyPackages.${system}) writeCueValidator;
      })
  ];
}
