{ config, ... }:
{
  boot.binfmt.emulatedSystems = config.lib.self.systems;
}
