{ config, lib, ... }:

{
  options.hosts.nuc = {
    listens = lib.mkOption {
      type = with lib.types; listOf anything;
      default = [
        { addr = "[::]"; port = config.ports.http; }
        { addr = "[::]"; port = config.ports.https; ssl = true; }
        { addr = "[::]"; port = config.ports.https-alternative; ssl = true; }
        { addr = "0.0.0.0"; port = config.ports.http; }
        { addr = "0.0.0.0"; port = config.ports.https; ssl = true; }
        { addr = "0.0.0.0"; port = config.ports.https-alternative; ssl = true; }
      ];
    };
  };
}
