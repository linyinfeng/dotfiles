{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  # Inputs that point back into this repository. A `system.constant` build must not embed this
  # tree, so they stay out of /etc/nix/inputs: `nixos/modules/system/constant.nix` registers
  # `self` as the `github:linyinfeng/dotfiles` flake ref instead, which carries `./systems`.
  workingTreeInputs = {
    inherit self;
    inherit (inputs) systems;
  };

  linkedInputs =
    if config.system.constant then
      removeAttrs (inputs // workingTreeInputs) (builtins.attrNames workingTreeInputs)
    else
      inputs // workingTreeInputs;

  flakeInputs = lib.filterAttrs (_: value: value ? outputs) linkedInputs;
in
{
  nix.registry = builtins.mapAttrs (_: flake: { inherit flake; }) flakeInputs;

  environment.etc = lib.mapAttrs' (
    name: value: lib.nameValuePair "nix/inputs/${name}" { source = value.outPath; }
  ) linkedInputs;

  nix.nixPath = [ "/etc/nix/inputs" ];
}
