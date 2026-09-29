{ lib, ... }:
{
  options.synchronize.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.enable = lib.mkEnableOption "syncing this user's shell history";
      }
    );
    default = { };
  };
}
