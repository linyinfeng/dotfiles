{ self, inputs, ... }:
{
  modules = with inputs; [
    bud.devshellModules.bud
  ];
  exportedModules = [
    ./devos.nix
    ./sops-nix.nix
  ];
}
