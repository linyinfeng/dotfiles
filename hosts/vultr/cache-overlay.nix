{ self, config, pkgs, ... }:

let
  cacheS3Host = self.lib.data.cache_s3_host;
  cacheBucketName = self.lib.data.cache_bucket_name;
  sigv4ProxyPort = config.ports.sigv4-proxy;
  sigv4ProxyAddress = "http://localhost:${toString sigv4ProxyPort}";
in
{
  services.nginx.virtualHosts."cache-overlay.*" = {
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
        proxy_pass https://cache.nixos.org;
      }
      if ($to_cache_nixos_org != 11) {
        set $pass_with_host $host;
        set $pass_with_auth $http_authorization;

        proxy_pass ${sigv4ProxyAddress};
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
      proxy_pass ${sigv4ProxyAddress};
    '';
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };

  systemd.services."cache-sigv4-proxy" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      ${pkgs.nur.repos.linyinfeng.aws-s3-reverse-proxy}/bin/aws-s3-reverse-proxy \
        --verbose \
        --allowed-endpoint="cache-overlay.li7g.com" \
        --aws-credentials="$AWS_ACCESS_KEY_ID,$AWS_SECRET_ACCESS_KEY" \
        --listen-addr=":${toString sigv4ProxyPort}" \
        --allowed-source-subnet=127.0.0.1/8 \
        --allowed-source-subnet=::1/128 \
        --upstream-endpoint="${cacheS3Host}"
    '';
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."cache_access_key".path}"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  sops.secrets."cache_key_id" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/vultr.yaml;
    restartUnits = [ "cache-sigv4-proxy.service" ];
  };
  sops.secrets."cache_access_key" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/vultr.yaml;
    restartUnits = [ "cache-sigv4-proxy.service" ];
  };
}
