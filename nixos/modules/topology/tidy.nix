{ lib, ... }:
{
  options.topology.tidy = lib.mkEnableOption "Tidy connections";
}
