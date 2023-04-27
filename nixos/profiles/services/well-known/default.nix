{...}: {
  services.nginx.virtualHosts."li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    # matrix
    locations."/.well-known/matrix/server".extraConfig = ''
      default_type application/json;
      return 200 '{ "m.server": "matrix.li7g.com:443" }';
    '';
    locations."/.well-known/matrix/client".extraConfig = ''
      add_header Access-Control-Allow-Origin '*';
      default_type application/json;
      return 200 '{ "m.homeserver": { "base_url": "https://matrix.li7g.com" } }';
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
