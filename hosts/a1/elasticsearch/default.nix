{ config, ... }:

{
  services.elasticsearch = {
    enable = true;
    cluster_name = "elasticsearch-a1";
    port = config.ports.elasticsearch;
    tcp_port = config.ports.elasticsearch-node-to-node;
    single_node = true;
    extraConf = ''
      xpack.ml.enabled: false # not supported on aarch64
    '';
  };

  services.nginx.virtualHosts."elasticsearch.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://localhost:${toString config.ports.elasticsearch}";
      extraConfig = ''
        auth_basic "elasticsearch";
        auth_basic_user_file ${config.sops.templates."elasticsearch-auth-file".path};
      '';
    };
  };
  systemd.services.nginx.restartTriggers = [
    config.sops.templates."elasticsearch-auth-file".file
  ];
  sops.templates."elasticsearch-auth-file" = {
    content = ''
      elasticsearch:${config.sops.placeholder."elasticsearch_hashed_password"}
    '';
    owner = "nginx";
  };
  sops.secrets."elasticsearch_hashed_password" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/a1.yaml;
    restartUnits = [ "nginx.service" ];
  };
}
