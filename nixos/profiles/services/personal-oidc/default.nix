{ config, lib, ... }:
let
  inherit (config.lib.self) data;
  cfg = config.services.personal-oidc;
  address = "http://127.0.0.1:${toString config.ports.personal-oidc}";
  authPath = "/oauth2/auth";
  proxy = authority: {
    proxyPass = address;
    recommendedProxySettings = false;
    extraConfig = ''
      proxy_set_header Host ${authority};
      proxy_set_header X-Forwarded-Host ${authority};
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-Uri $request_uri;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
      proxy_buffer_size 16k;
      proxy_buffers 8 8k;
    '';
  };
in
{
  options.services.personal-oidc.allowedEmails = lib.mkOption {
    type = lib.types.nonEmptyListOf (lib.types.strMatching "[^[:space:]]+@[^[:space:]]+");
    default = [ "lin.yinfeng@outlook.com" ];
    description = "Zitadel email addresses allowed into applications that use this shared proxy.";
  };

  config = {
    lib.personalOidc = {
      authRequest = "auth_request ${authPath};";
      loginRedirect = "error_page 401 = /oauth2/start;";
      # Pass a fixed public authority or a variable restricted to known hosts.
      nginxLocations =
        authority:
        let
          authProxy = proxy authority;
        in
        {
          "/oauth2/" = authProxy;
          "= ${authPath}" = authProxy // {
            extraConfig = authProxy.extraConfig + ''
              internal;
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
            '';
          };
        };
    };

    sops.secrets."zitadel_personal_oidc_client_secret" = {
      terraformOutput.enable = true;
      restartUnits = [ "oauth2-proxy.service" ];
    };
    sops.secrets."personal_oidc_cookie_secret" = {
      terraformOutput.enable = true;
      restartUnits = [ ];
    };
    sops.templates.personal-oidc-env = {
      content = ''
        OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.personal_oidc_cookie_secret}
      '';
      restartUnits = [ "oauth2-proxy.service" ];
    };

    services.oauth2-proxy = {
      enable = true;
      provider = "oidc";
      oidcIssuerUrl = data.zitadel_issuer;
      clientID = data.zitadel_personal_oidc_client_id;
      clientSecretFile = config.sops.secrets.zitadel_personal_oidc_client_secret.path;
      keyFile = config.sops.templates.personal-oidc-env.path;
      cookie.name = "__Host-personal-oidc";
      email.addresses = lib.concatLines cfg.allowedEmails;
      scope = "openid profile email";
      httpAddress = address;
      upstream = "static://202";
      reverseProxy = true;
      trustedProxyIP = [ "127.0.0.1/32" ];
      redirectURL = "/oauth2/callback";
      extraConfig = {
        code-challenge-method = "S256";
        cookie-samesite = "lax";
        insecure-oidc-skip-nonce = false;
      };
    };
  };
}
