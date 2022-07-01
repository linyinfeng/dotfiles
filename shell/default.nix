{ self, inputs, ... }:
{
  modules = with inputs; [
    bud.devshellModules.bud
  ];
  exportedModules = [
    ./terraform
    ./devos.nix
  ];
}
