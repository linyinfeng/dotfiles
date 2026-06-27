{ config, ... }:
{
  home-manager.users.agent = { osConfig, lib, ... }: {
    programs.opencode.web = {
      enable = true;
      environmentFile = osConfig.sops.templates."opencode-web-env".path;
      extraArgs = [
        "--hostname"
        "::1"
        "--port"
        (toString osConfig.ports.opencode-web)
        "--cors"
        "https://opencode.li7g.com:8443"
        "--cors"
        "https://opencode.ts.li7g.com"
        "--cors"
        "https://opencode.dn42.li7g.com"
        "--print-logs"
        "--log-level"
        "INFO"
      ];
    };
    systemd.user.services.opencode-web.Service.Environment =
      lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.stringEnvironment;
  };
  services.nginx.virtualHosts."opencode.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.opencode-web}";
    };
  };
  sops.templates."opencode-web-env" = {
    content = ''
      OPENCODE_SERVER_PASSWORD=${config.sops.placeholder."opencode_web_password"}
      GH_TOKEN=${config.sops.placeholder."github_token_agent"}
    '';
    owner = "agent";
  };
  sops.secrets."opencode_web_password" = {
    terraformOutput.enable = true;
    restartUnits = [ ];
  };
  sops.secrets."github_token_agent" = {
    predefined.enable = true;
    restartUnits = [ ];
    owner = "agent";
  };
}
