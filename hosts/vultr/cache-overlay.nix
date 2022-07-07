# TODO not working

{ self, config, ... }:

let
  cacheS3Url = self.lib.data.cache_s3_url;
  cacheBucketName = self.lib.data.cache_bucket_name;
in
{
  security.acme.certs."main".extraDomainNames = [
    "cache-overlay.li7g.com"
  ];
  services.nginx.virtualHosts."cache-overlay.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".extraConfig = ''
      set $to_cache_nixos_org 0;
      if ($request_method ~ ^GET|HEAD$) {
        set $to_cache_nixos_org 1;
      }
      if ($uri ~ ^.*\.narinfo$) {
        set $to_cache_nixos_org 1$to_cache_nixos_org;
      }

      if ($to_cache_nixos_org = 11) {
        set $pass_with_host cache.nixos.org;
        set $pass_with_auth "";

        rewrite /${cacheBucketName}/(.*) /$1 break;
        error_page 404 = @fallback;
        proxy_pass  https://cache.nixos.org;
      }
      if ($to_cache_nixos_org != 11) {
        set $pass_with_host $host;
        set $pass_with_auth $http_authorization;

        proxy_pass ${cacheS3Url};
      }

      proxy_intercept_errors on;
      proxy_set_header Host $pass_with_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $pass_with_host;
      proxy_set_header Authorization $pass_with_auth;
    '';
    locations."@fallback".extraConfig = ''
      rewrite /(.*) /${cacheBucketName}/$1 break;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header Authorization $http_authorization;
      proxy_pass ${cacheS3Url};
    '';
    locations."/${cacheBucketName}/nix-cache-info".proxyPass = cacheS3Url;
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };
}
