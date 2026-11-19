{ config, lib, ... }:
let
  inherit (config.lib) personalOidc;
  inherit (config) ports;
  direct = "hermes.li7g.com";
  proxied = "hermes-proxy.li7g.com";
  dashboard = "127.0.0.1:${toString ports.hermes-dashboard}";
  protected = {
    proxyPass = "http://${dashboard}";
    recommendedProxySettings = false;
    proxyWebsockets = true;
    extraConfig = ''
      if ($hermes_origin = invalid) { return 403; }
      ${personalOidc.authRequest}
      proxy_set_header Host ${dashboard};
      proxy_set_header Origin $hermes_origin;
      proxy_read_timeout 600s;
    '';
  };
in
lib.mkIf config.world.profiles.services.personal-oidc.enable {
  home-manager.users.agent.programs.hermes-team = {
    dashboard.port = ports.hermes-dashboard;
    webhook.tokenFile = config.sops.secrets.hermes_grafana_webhook_token.path;
  };

  sops.secrets."hermes_grafana_webhook_token" = {
    terraformOutput.enable = true;
    owner = "agent";
    # TODO: Restart the user unit automatically when this credential rotates.
    restartUnits = [ ];
  };

  services.nginx = {
    appendHttpConfig = ''
      map $host $hermes_authority {
        ${direct} ${direct}:${toString ports.https-alternative};
        ${proxied} ${proxied};
      }

      # Hermes checks WebSocket Origin against the loopback listener. Translate
      # only an exact same-origin browser request from one of our HTTPS hosts.
      map $http_origin $hermes_origin_authority {
        default invalid;
        "" "";
        "https://${direct}:${toString ports.https-alternative}" "${direct}:${toString ports.https-alternative}";
        "https://${proxied}" "${proxied}";
      }
      map "$hermes_authority|$hermes_origin_authority" $hermes_origin {
        default invalid;
        ~[|]$ "";
        "${direct}:${toString ports.https-alternative}|${direct}:${toString ports.https-alternative}" "http://${dashboard}";
        "${proxied}|${proxied}" "http://${dashboard}";
      }
    '';
    virtualHosts.${direct} = {
      serverAliases = [ proxied ];
      forceSSL = true;
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
      extraConfig = ''
        if ($hermes_authority = "") { return 421; }
      '';
      locations = personalOidc.nginxLocations "$hermes_authority" // {
        "/" = protected // {
          extraConfig = protected.extraConfig + personalOidc.loginRedirect;
        };
        "/api/" = protected;
        "= /grafana/alerts" = {
          proxyPass = "http://127.0.0.1:${toString ports.hermes-team-webhook}";
          extraConfig = ''
            client_max_body_size 1m;
            proxy_request_buffering on;
          '';
        };
      };
    };
  };
}
