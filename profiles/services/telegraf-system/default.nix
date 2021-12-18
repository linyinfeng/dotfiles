{ config, pkgs, ... }:

let
  influxdbPort = 3004;
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
        {
          urls = [ "http://nuc.ts.li7g.com:${toString influxdbPort}" ];
          token = "$INFLUX_TOKEN";
          organization = "main-org";
          bucket = "main";
        }
      ];
      inputs = {
        cpu = [
          {
            percpu = true;
            totalcpu = true;
            collect_cpu_time = false;
            report_active = false;
          }
        ];
        disk = [
          {
            ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "overlay" "aufs" "squashfs" ];
          }
        ];
        diskio = [{ }];
        mem = [{ }];
        net = [{ }];
        processes = [{ }];
        swap = [{ }];
        system = [{ }];
        sensors = [{ }];
      };
    };
  };
  systemd.services.telegraf.path = with pkgs; [
    lm_sensors
  ];
  sops.secrets."influxdb/token" = { };
  sops.templates."telegraf-environment".content = ''
    INFLUX_TOKEN=${config.sops.placeholder."influxdb/token"}
  '';
}
