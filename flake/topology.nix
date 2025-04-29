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
          {
            inherit (self) nixosConfigurations;
            _module.args = { inherit self; };
          }
        ];
      };
    };
}
