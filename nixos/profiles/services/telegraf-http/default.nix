{
  config,
  pkgs,
  lib,
  ...
}: let
  tld = "li7g.com";
  servicesCnameMappings = config.lib.self.data.service_cname_mappings;
  unproxiedServiceUrls = {
    hydra = [
      {
        url = "https://hydra.ts.li7g.com";
        code = 200;
      }
    ];
    transmission = [
      # do not test transmission daemon:
      # too many unsuccessful login attempts. please restart transmission-daemon.
      # {
      #   url = "https://transmission.ts.li7g.com/transmission";
      #   code = 401;
      # }
      {
        url = "https://transmission.ts.li7g.com/files/";
        code = 401;
      }
    ];
    jellyfin = [
      {
        url = "https://jellyfin.ts.li7g.com/web/";
        code = 200;
      }
    ];
    hledger = [
      {
        url = "https://hledger.ts.li7g.com";
        code = 401;
      }
    ];
    minio = [
      {
        url = "https://minio.li7g.com";
        code = 403;
      }
    ];
    "shanghai.derp" = [];
    dst = [];
    matrix-qq = [];
    smtp = [];
  };
  overrides = {
    alertmanager = [
      {
        url = "https://alertmanager.li7g.com";
        code = 401;
      }
    ];
    box = [
      {
        url = "https://box.li7g.com/accounts/login/?next=/";
        code = 200;
      }
    ];
    loki = [
      {
        url = "https://loki.li7g.com";
        code = 401;
      }
    ];
    tar = [
      {
        url = "https://tar.li7g.com/healthcheck";
        code = 200;
      }
    ];
  };
  mkServiceCfg = name: cnameMapping:
    if cnameMapping.proxy
    then [
      {
        url = "https://${name}.li7g.com";
        code = 200;
      }
    ]
    else unproxiedServiceUrls.${name};
  serviceCfgs = lib.recursiveUpdate (lib.mapAttrs mkServiceCfg servicesCnameMappings) overrides;
  urlCfgs = lib.flatten (lib.mapAttrsToList (_name: cfg: cfg) serviceCfgs);
  allCodes = lib.unique (lib.lists.map (c: c.code) urlCfgs);
in {
  services.telegraf.extraConfig = {
    inputs = {
      http_response =
        lib.lists.map (code: {
          urls = lib.lists.map (c: c.url) (lib.filter (c: c.code == code) urlCfgs);
          response_status_code = code;
          tags.output_bucket = "http";
        })
        allCodes;
    };
  };
}
