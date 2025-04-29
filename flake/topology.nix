{
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      topology = {
        inherit pkgs;
        modules = [
          ../topology
          { inherit (self) nixosConfigurations; }
        ];
      };
    };

  # special checks
  flake.checks = {
    "x86_64-linux" = {
      topology = self.topology."x86_64-linux".config.output;
    };
  };
}
