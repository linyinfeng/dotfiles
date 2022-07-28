{ config, pkgs, ... }:

let
  nucInfluxdb = bucket: {
    urls = [ "https://influxdb.li7g.com" ];
    token = "$INFLUX_TOKEN";
    organization = "main-org";
    bucket = bucket;
    tagpass.output_bucket = [ bucket ];
  };
in
{
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
        (nucInfluxdb "main")
        (nucInfluxdb "system")
        (nucInfluxdb "minio")
        (nucInfluxdb "minecraft")
      ];
      inputs = {
        cpu = [
          {
            percpu = true;
            totalcpu = true;
            collect_cpu_time = false;
            report_active = false;
            tags.output_bucket = "system";
          }
        ];
        disk = [
          {
            ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "overlay" "aufs" "squashfs" ];
            tags.output_bucket = "system";
          }
        ];
        diskio = [{
          tags.output_bucket = "system";
        }];
        mem = [{
          tags.output_bucket = "system";
        }];
        net = [{
          tags.output_bucket = "system";
        }];
        processes = [{
          tags.output_bucket = "system";
        }];
        swap = [{
          tags.output_bucket = "system";
        }];
        system = [{
          tags.output_bucket = "system";
        }];
        sensors = [{
          tags.output_bucket = "system";
        }];
      };
    };
  };
  systemd.services.telegraf.path = with pkgs; [
    lm_sensors
  ];
  sops.secrets."influxdb_token".sopsFile = config.sops.secretsDir + /terraform/infrastructure.yaml;
  sops.templates."telegraf-environment".content = ''
    INFLUX_TOKEN=${config.sops.placeholder."influxdb_token"}
  '';
}
