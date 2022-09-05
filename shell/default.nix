{ self, inputs, ... }:
{
  modules = with inputs; [ ];
  exportedModules = [
    ./terraform
    ./devos.nix
  ];
}
