{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  caCfg = cfg.certificateAuthority;
in
  lib.mkIf (cfg.enable && caCfg.trust) {
    security.pki.certificateFiles = [./dn42.crt];
  }
