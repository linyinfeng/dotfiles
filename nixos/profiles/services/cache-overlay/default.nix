{ config, lib, ... }:
let
  port = config.ports.nix-cache-overlay;
  s3Endpoint = config.lib.self.data.r2_s3_api_url;
in
{
  services.nix-cache-overlay = {
    enable = true;
    listen = "[::1]:${toString port}";
    endpoint = "https://${s3Endpoint}";
    environmentFile = config.sops.templates."nix-cache-overlay-env".path;
  };
  systemd.services.nix-cache-overlay.environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  services.nginx.virtualHosts."cache-overlay.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://[::1]:${toString port}";
    extraConfig = ''
      client_max_body_size 4G;
    '';
  };

  sops.templates."nix-cache-overlay-env".content = ''
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."r2_cache_key_id"}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."r2_cache_access_key"}
    AWS_EC2_METADATA_DISABLED=true
    NIX_CACHE_OVERLAY_TOKEN=${config.sops.placeholder."nix_cache_overlay_token"}
  '';
  sops.secrets."r2_cache_key_id" = {
    terraformOutput.enable = true;
    restartUnits = [ "nix-cache-overlay.service" ];
  };
  sops.secrets."r2_cache_access_key" = {
    terraformOutput.enable = true;
    restartUnits = [ "nix-cache-overlay.service" ];
  };
  sops.secrets."nix_cache_overlay_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "nix-cache-overlay.service" ];
  };
}
