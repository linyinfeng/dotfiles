# TODO wait for https://nixpk.gs/pr-tracker.html?pr=185116
{ inputs, config, lib, pkgs, ... }:

# bootspec-rfc
let
  children = lib.mapAttrs
    (childName: childConfig: childConfig.configuration.system.build.toplevel)
    config.specialisation;
  bootSpec = import "${inputs.bootspec-rfc}/nixos/modules/system/activation/bootspec.nix" {
    inherit config pkgs lib children;
  };
in
{
  # bootspec-rfc
  imports = [
    "${inputs.bootspec-rfc}/nixos/modules/system/boot/loader/external/external.nix"
  ];
  system.extraSystemBuilderCmds = ''
    ${lib.optionalString (!config.boot.isContainer) ''
      ${bootSpec.writer}
    ''}
  '';
}
