{ lib, ... }:

{
  options.hosts.nuc = {
    listens = lib.mkOption {
      type = with lib.types; listOf anything;
      default = [
        { addr = "[::]"; port = 80; }
        { addr = "[::]"; port = 443; ssl = true; }
        { addr = "[::]"; port = 8443; ssl = true; }
        { addr = "0.0.0.0"; port = 80; }
        { addr = "0.0.0.0"; port = 443; ssl = true; }
        { addr = "0.0.0.0"; port = 8443; ssl = true; }
      ];
    };
    ports = {
      hydra = lib.mkOption {
        type = lib.types.port;
        default = 3001;
      };
      nixServe = lib.mkOption {
        type = lib.types.port;
        default = 3002;
      };
    };
  };
}
