{ inputs, ... }:
{
  imports = [ inputs.run0-sudo-shim.nixosModules.default ];
}
