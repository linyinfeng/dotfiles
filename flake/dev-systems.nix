{ config, lib, ... }:
{
  devSystems = lib.subtractLists [ "riscv64-linux" ] config.systems;
}
