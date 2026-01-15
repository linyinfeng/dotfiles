{
  config,
  pkgs,
  lib,
  ...
}:
let
  port = config.ports.fw-proxy-subscription;
  python = pkgs.python3;
  pyPkgs = python.pkgs;
  subscriptionServer = pyPkgs.buildPythonPackage {
    name = "fw-proxy-subscription";
    src = ./_src;
    pyproject = true;
    build-system = [ pyPkgs.setuptools ];
    dependencies =
      with pyPkgs;
      [
        flask
        aiohttp
      ]
      ++ flask.optional-dependencies.async;
  };
in
{
  passthru.fw-proxy-subscription-server = subscriptionServer;
  systemd.services.fw-proxy-subscription = {
    script = ''
      waitress-serve --port=${toString port} --call fw_proxy_subscription:create_app
    '';
    path =
      let
        py = python.withPackages (p: [
          p.waitress
          subscriptionServer
        ]);
      in
      [
        py
        py.pkgs.waitress
      ];
    serviceConfig = {
      DynamicUser = true;
      EnvironmentFile = [
        config.sops.templates."fw-proxy-subscription-env".path
      ];
    };
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    wantedBy = [ "multi-user.service" ];
  };
  services.nginx.virtualHosts."subscription.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/fw-proxy/".proxyPass = "http://127.0.0.1:${toString port}/";
  };
  sops.templates."fw-proxy-subscription-env".content = ''
    FW_PROXY_SUBSCRIPTION_SECRET=${config.sops.placeholder."fw_proxy_subscription_password"}
    FW_PROXY_SUBSCRIPTION_UPSTREAM_URL=${config.sops.placeholder."fw_proxy_sing_box"}
  '';
  sops.secrets."fw_proxy_subscription_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "fw-proxy-subscription.service" ];
  };
  sops.secrets."fw_proxy_sing_box" = {
    predefined.enable = true;
    restartUnits = [ "fw-proxy-subscription.service" ];
  };
}
