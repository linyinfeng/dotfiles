{ inputs, ... }:
{
  imports = [ inputs.nixos-wsl.nixosModules.wsl ];
}
