{ inputs, ... }:
{
  imports = [ inputs.preservation.nixosModules.preservation ];
}
