{ lib, ... }:

{
  options.hosts.a1 = {
    ports = {
      hydra = {
        type = lib.types.port;
        default = 3001;
      };
    };
  };
}
