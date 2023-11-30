{...}: {
  services.nginx.virtualHosts."li7g.com" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    # matrix
    locations."/.well-known/matrix/".alias = "${./_root/matrix}/";
    locations."=/.well-known/matrix/server".extraConfig = ''
      default_type application/json;
      rewrite ^(.*)$ $1.json last;
    '';
    locations."=/.well-known/matrix/client".extraConfig = ''
      add_header Access-Control-Allow-Origin '*';
      default_type application/json;
      rewrite ^(.*)$ $1.json last;
    '';
    # mastodon
    locations."/.well-known/host-meta".extraConfig = ''
      return 301 https://mastodon.li7g.com$request_uri;
    '';
    locations."/.well-known/webfinger".extraConfig = ''
      return 301 https://mastodon.li7g.com$request_uri;
    '';
  };
}
