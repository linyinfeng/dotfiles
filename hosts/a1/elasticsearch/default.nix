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
}
