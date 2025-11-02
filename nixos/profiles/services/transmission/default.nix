{ config, pkgs, ... }:
let
  rpcPort = config.ports.transmission-rpc;
in
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    openFirewall = true;
    credentialsFile = config.sops.templates."transmission-credentials".path;
    settings = {
      rpc-port = rpcPort;
      rpc-bind-address = "::";
      rpc-authentication-required = true;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
  };

  services.nginx.virtualHosts."transmission.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/transmission".proxyPass =
      "http://localhost:${toString config.services.transmission.settings.rpc-port}";
    locations."/files/" = {
      alias = "/var/lib/transmission/Downloads/";
      extraConfig = ''
        charset UTF-8;
        autoindex on;
        auth_basic "transmission";
        auth_basic_user_file ${config.sops.templates."transmission-auth-file".path};
      '';
    };
  };
  users.users.nginx.extraGroups = [ config.users.groups.transmission.name ];

  services.samba.settings.transmission = {
    "path" = "/var/lib/transmission/Downloads";
    "read only" = true;
    "browseable" = true;
    "comment" = "Transmission downloads";
  };

  sops.templates."transmission-credentials".content = builtins.toJSON {
    rpc-username = config.sops.placeholder."transmission_username";
    rpc-password = config.sops.placeholder."transmission_password";
  };

  sops.templates."transmission-auth-file" = {
    content = ''
      ${config.sops.placeholder."transmission_username"}:${
        config.sops.placeholder."transmission_hashed_password"
      }
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."transmission_username" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
  sops.secrets."transmission_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
  sops.secrets."transmission_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "transmission.service" ];
  };
}
