{ self, ... }:
{
  perSystem =
    { ... }:
    {
      _module.args.flake-lib = self.lib;
    };
}
