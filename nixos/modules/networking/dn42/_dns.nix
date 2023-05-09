{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  dnsCfg = cfg.dns;
in
  lib.mkIf (cfg.enable && dnsCfg.enable) {
    systemd.network.networks = {
      ${cfg.interfaces.dummy.name} = {
        networkConfig = {
          DNS = dnsCfg.nameServers;
          Domains = lib.lists.map (d: "~${d}") dnsCfg.domains;
        };
      };
    };
  }
