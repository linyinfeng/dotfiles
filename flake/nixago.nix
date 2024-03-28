{ config, lib, ... }:
{
  perSystem =
    { system, ... }:
    {
      imports = lib.optional (lib.elem system config.devSystems) ../nixago;
    };
}
