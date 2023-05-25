{
  config,
  lib,
  ...
}: let
  servicesCnameMappings = config.lib.self.data.service_cname_mappings;
  unproxiedServiceUrls = {
    attic-upload = [
      {
        url = "https://attic-upload.li7g.com";
        code = 200;
      }
    ];
    prebuilt-zip = [
      {
        url = "https://prebuilt.zip";
        code = 302;
      }
    ];
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
    box = [
      {
        url = "https://box.li7g.com/accounts/login/?next=/";
        code = 200;
      }
    ];
    tar = [
      {
        url = "https://tar.li7g.com/healthcheck";
        code = 200;
      }
    ];
    dn42 = [
      {
        url = "https://dn42.li7g.com/info.json";
        code = 200;
      }
    ];
    bird-lg = [
      {
        url = "https://bird-lg.li7g.com";
        code = 302;
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
