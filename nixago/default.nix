{ config, lib, ... }:
{
  nixago.configs = [
    {
      output = ".sops.yaml";
      format = "yaml";
      data = import ./sops-yaml.nix { inherit lib; };
    }
  ];
  devshells.default.devshell.startup."nixago".text = config.nixago.shellHook;
}
