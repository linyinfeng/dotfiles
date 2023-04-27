{
  config,
  pkgs,
  ...
}: let
  mainInfluxdb = bucket: {
    urls = ["https://influxdb.li7g.com"];
    token = "$INFLUX_TOKEN";
    organization = "main-org";
    bucket = bucket;
    tagpass.output_bucket = [bucket];
  };
in {
  services.telegraf = {
    enable = true;
    environmentFiles = [
      config.sops.templates."telegraf-environment".path
    ];
    extraConfig = {
      agent = {
        interval = "10s";
        round_interval = true;
        metric_batch_size = 1000;
        metric_buffer_limit = 10000;
        collection_jitter = "5s";
        flush_interval = "10s";
        flush_jitter = "5s";
      };
      outputs.influxdb_v2 = [
        (mainInfluxdb "main")
        (mainInfluxdb "system")
        (mainInfluxdb "minio")
        (mainInfluxdb "minecraft")
        (mainInfluxdb "http")
      ];
    };
  };
  sops.secrets."influxdb_token" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = ["telegraf.service"];
  };
  sops.templates."telegraf-environment".content = ''
    INFLUX_TOKEN=${config.sops.placeholder."influxdb_token"}
  '';
}
