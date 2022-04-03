{ pkgs, ... }:

let
  terraform = pkgs.terraform;
  wrapped = pkgs.writeShellScriptBin "terraform" ''
    ${pkgs.sops}/bin/sops exec-env ${../../secrets/terraform.yaml} "${terraform}/bin/terraform \"$@\""
  '';
  metaOverrided = wrapped.overrideAttrs (old: {
    inherit (terraform) meta;
  });
in
{
  commands = [
    {
      package = metaOverrided;
      category = "infrustructure";
    }
  ];
}
