{ lib, ... }:
{
  options.system.nproc = lib.mkOption { type = lib.types.int; };
}
