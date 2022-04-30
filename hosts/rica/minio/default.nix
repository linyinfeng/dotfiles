{config, pkgs, ...}:

let
  minioPort = 9000;
  minioConsolePort = 9001;
  minioAddress = "http://localhost:${toString minioPort}";
  minioRequiredProxyHeaders = pkgs.writeText "minio-required-proxy-headers.conf" ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
  '';
  proxyPassToMinio = ''
    include ${minioRequiredProxyHeaders};
    proxy_pass ${minioAddress};
  '';
in
{
  services.minio = {
    enable = true;
    listenAddress = "127.0.0.1:${toString minioPort}";
    consoleAddress = "127.0.0.1:${toString minioConsolePort}";
    rootCredentialsFile = config.sops.secrets."minio/root".path;
  };
  sops.secrets."minio/root".sopsFile = config.sops.secretsDir + /rica.yaml;
  services.nginx.virtualHosts."minio.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".proxyPass = minioAddress;
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
  services.nginx.virtualHosts."cache.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".extraConfig = ''
      rewrite /(.*) /cache/$1 break;
      ${proxyPassToMinio}
    '';
  };
  services.nginx.virtualHosts."minio-overlay.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".extraConfig = ''
      if ($request_method !~ ^GET|HEAD$) {
        set $pass_with_host $host;
        set $pass_with_auth $http_authorization;

        proxy_pass ${minioAddress};
      }
      if ($request_method ~ ^GET|HEAD$) {
        set $pass_with_host cache.nixos.org;
        set $pass_with_auth "";

        rewrite /cache/(.*) /$1 break;
        error_page 404 = @minioFallback;
        proxy_pass  https://cache.nixos.org;
      }

      proxy_intercept_errors on;
      proxy_set_header Host $pass_with_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $pass_with_host;
      proxy_set_header Authorization $pass_with_auth;
    '';
    locations."@minioFallback".extraConfig = ''
      rewrite /(.*) /cache/$1 break;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header Authorization $http_authorization;
      proxy_pass ${minioAddress};
    '';
    locations."/cache/nix-cache-info".proxyPass = minioAddress;
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
  services.nginx.virtualHosts."minio-console.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".proxyPass = "http://localhost:${toString minioConsolePort}";
  };
}
