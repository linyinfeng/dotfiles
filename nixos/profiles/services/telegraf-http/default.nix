{ config, lib, ... }:
let
  servicesCnameMappings = config.lib.self.data.service_cname_mappings;
  unproxiedServiceUrls = {
    prebuilt-zip = [
      {
        url = "https://prebuilt.zip";
        code = 302;
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
    minio = [
      {
        url = "https://minio.li7g.com";
        code = 403;
      }
    ];
    matrix-qq = [
      # TODO broken
      # {
      #   url = "https://matrix-qq.ts.li7g.com";
      #   code = 404;
      # }
    ];
    nextcloud = [
      {
        url = "https://nextcloud.ts.li7g.com:8443/login";
        code = 200;
      }
    ];
    mc = [
      # currently not hosted
      # {
      #   url = "https://mc.ts.li7g.com";
      #   code = 200;
      # }
    ];
    hydra = [
      {
        url = "https://hydra.ts.li7g.com";
        code = 200;
      }
    ];
    smtp = [ ];
    teamspeak = [ ];
    portal = [ ];
    subscription = [ ];
    rathole-ad-hoc = [ ];
  };
  overrides = {
    box = [
      # {
      #   url = "https://box.li7g.com/accounts/login/?next=/";
      #   code = 200;
      # }
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
    hledger = [
      {
        url = "https://hledger.li7g.com";
        code = 401;
      }
    ];
    cache-overlay = [
      {
        url = "https://cache-overlay.li7g.com/zhl06z4lrfrkw5rp0hnjjfrgsclzvxpm.narinfo";
        code = 200;
      }
    ];
    matrix = [
      {
        url = "https://matrix.li7g.com/_matrix/client/versions";
        code = 200;
      }
    ];
    keycloak = [
      {
        url = "https://keycloak.li7g.com";
        code = 302;
      }
    ];
    sicp-staging = [
      {
        url = "https://sicp-staging.li7g.com/2024/oj/web/";
        code = 200;
      }
    ];
    sicp-tutorials = [
      {
        url = "https://sicp-tutorials.li7g.com";
        code = 401;
      }
    ];
  };
  mkServiceCfg =
    name: cnameMapping:
    if cnameMapping.proxy then
      [
        {
          url = "https://${name}.li7g.com";
          code = 200;
        }
      ]
    else
      unproxiedServiceUrls.${name};
  serviceCfgs = lib.recursiveUpdate (lib.mapAttrs mkServiceCfg servicesCnameMappings) overrides;
  urlCfgs = lib.flatten (lib.mapAttrsToList (_name: cfg: cfg) serviceCfgs);
  allCodes = lib.unique (lib.lists.map (c: c.code) urlCfgs);
in
{
  assertions = [
    (
      let
        unproxiedCnameMappings = lib.attrNames (lib.filterAttrs (_: m: !m.proxy) servicesCnameMappings);
        unproxiedCfgs = lib.attrNames unproxiedServiceUrls;
        inherit (lib.lists) subtractLists;
        uncoveredCfgs = subtractLists unproxiedCnameMappings unproxiedCfgs;
        uncoveredCnameMappings = subtractLists unproxiedCfgs unproxiedCnameMappings;
      in
      {
        assertion = uncoveredCfgs == [ ] && uncoveredCnameMappings == [ ];
        message = ''
          unproxied services configurations does not match with services unproxied CNAME mappings
          uncovered configurations: ${toString uncoveredCfgs}
          uncovered CNAME mappings: ${toString uncoveredCnameMappings}
        '';
      }
    )
    (
      let
        invalidOverrides = lib.lists.subtractLists (lib.attrNames (
          lib.filterAttrs (_: m: m.proxy) servicesCnameMappings
        )) (lib.attrNames overrides);
      in
      {
        assertion = invalidOverrides == [ ];
        message = "invalid overrides: ${toString invalidOverrides}";
      }
    )
  ];
  services.telegraf.extraConfig.outputs.influxdb_v2 = [
    (config.lib.telegraf.mkMainInfluxdbOutput "http")
  ];
  services.telegraf.extraConfig = {
    inputs = {
      http_response = lib.lists.map (code: {
        urls = lib.lists.map (c: c.url) (lib.filter (c: c.code == code) urlCfgs);
        response_status_code = code;
        tags.output_bucket = "http";
      }) allCodes;
    };
  };
}
