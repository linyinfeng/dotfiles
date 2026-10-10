{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.self) data;
  inherit (config.networking) hostName;
  grpcPort = config.ports.hydra-grpc;
  restPort = config.ports.hydra-rest;
in
{
  # exposed by the ports.https-alternative SNI split in hosts/nuc: that name goes to
  # this gRPC port, everything else to the ports.https-internal http listener
  services.hydra.queueRunner = {
    grpc.port = grpcPort;
    rest.port = restPort;
    # builders authenticate with their own host certificate
    mtls = {
      serverCertPath = pkgs.writeText "hydra-queue-runner-cert.pem" data.hosts.${hostName}.mtls_cert_pem;
      serverKeyPath = config.sops.secrets."mtls_private_key_pem".path;
      clientCaCertPath = pkgs.writeText "hydra-mtls-ca.pem" data.ca_cert_pem;
    };
  };
  # the build agent shares this host with the queue runner: skip the public name
  services.hydra-builder.queueRunnerAddr = lib.mkForce "https://[::1]:${toString grpcPort}";

  # only the read-only status and metrics paths: the REST api can also enqueue builds
  services.nginx.virtualHosts."hydra-runner.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/status".proxyPass = "http://[::1]:${toString restPort}";
    locations."/metrics".proxyPass = "http://[::1]:${toString restPort}";
    locations."/".extraConfig = "return 404;";
  };

  systemd.services.hydra-queue-runner.serviceConfig.SupplementaryGroups = [
    config.users.groups.nix-access-tokens.name
  ];
}
