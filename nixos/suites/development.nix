{ lib, ... }:
{
  world.profiles.development.documentation.enable = lib.mkDefault true;
  world.profiles.programs.adb.enable = lib.mkDefault true;
  world.profiles.programs.probe-rs.enable = lib.mkDefault true;
  world.profiles.programs.qrcp.enable = lib.mkDefault true;
  world.profiles.programs.direnv.enable = lib.mkDefault true;
  world.profiles.services.gnupg.enable = lib.mkDefault true;
  world.profiles.services.nixseparatedebuginfod.enable = lib.mkDefault true;
  world.profiles.services.envfs.enable = lib.mkDefault true;
  world.profiles.nix.nix-ld.enable = lib.mkDefault true;
}
