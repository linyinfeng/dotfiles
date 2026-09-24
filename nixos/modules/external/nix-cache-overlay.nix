{ inputs, ... }:
{
  imports = [ inputs.nix-cache-overlay.nixosModules.default ];
}
