{
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.self) data;
  inherit (config.networking) hostName;
  caCertFile = pkgs.writeText "hydra-builder-ca.pem" data.ca_cert_pem;
in
{
  imports = [ ../../boot/secure-boot/_keys.nix ];
  services.hydra-builder = {
    enable = true;
    queueRunnerAddr = "https://hydra-runner.li7g.com:${toString config.ports.https-alternative}";
    mtls = {
      serverRootCaCertPath = caCertFile;
      clientCertPath = pkgs.writeText "hydra-builder-cert.pem" data.hosts.${hostName}.mtls_cert_pem;
      clientKeyPath = config.sops.secrets."mtls_private_key_pem".path;
      domainName = "hydra-runner.li7g.com";
    };
  };
  # the queue runner reads the same host key
  sops.secrets."mtls_private_key_pem" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    group = "hydra";
    mode = "440";
    restartUnits = [ "hydra-builder.service" ];
  };
}
