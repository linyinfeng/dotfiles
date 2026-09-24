{ ... }:
{
  world.profiles = {
    development.documentation.enable = true;
    nix.nix-ld.enable = true;
    programs = {
      adb.enable = true;
      direnv.enable = true;
      probe-rs.enable = true;
      qrcp.enable = true;
    };
    services = {
      envfs.enable = true;
      gnupg.enable = true;
      nixseparatedebuginfod.enable = true;
    };
  };
}
