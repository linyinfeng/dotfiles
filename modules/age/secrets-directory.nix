{ lib, ... }:

{
  options.age.secrets-directory = lib.mkOption {
    type = lib.types.path;
    default = ../../secrets;
    description = ''
      Directory contains age secrets.
    '';
  };
}
