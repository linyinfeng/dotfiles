{config, ...}: let
  mainInfluxdb = bucket: {
    urls = [config.lib.self.data.influxdb_url];
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
        (mainInfluxdb "system")
        (mainInfluxdb "minio")
        (mainInfluxdb "minecraft")
        (mainInfluxdb "http")
      ];
    };
  };
  sops.secrets."influxdb_token" = {
    terraformOutput.enable = true;
    restartUnits = ["telegraf.service"];
  };
  sops.templates."telegraf-environment".content = ''
    INFLUX_TOKEN=${config.sops.placeholder."influxdb_token"}
  '';
}
