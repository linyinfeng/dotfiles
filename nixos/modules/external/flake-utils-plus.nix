{ inputs, ... }:
{
  imports = [ inputs.flake-utils-plus.nixosModules.autoGenFromInputs ];
}
