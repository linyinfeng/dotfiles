{ config, pkgs, ... }:
{
  services.telegraf.extraConfig.outputs.influxdb_v2 = [
    (config.lib.telegraf.mkMainInfluxdbOutput "system")
  ];
  services.telegraf.extraConfig = {
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
      procstat = [
        {
          pattern = ".*";
          cmdline_tag = true;
          pid_tag = true;
          tags.output_bucket = "system";
        }
      ];
      disk = [
        {
          ignore_fs = [
            "tmpfs"
            "devtmpfs"
            "devfs"
            "overlay"
            "aufs"
            "squashfs"
          ];
          tags.output_bucket = "system";
        }
      ];
      diskio = [ { tags.output_bucket = "system"; } ];
      mem = [ { tags.output_bucket = "system"; } ];
      net = [ { tags.output_bucket = "system"; } ];
      processes = [ { tags.output_bucket = "system"; } ];
      swap = [ { tags.output_bucket = "system"; } ];
      system = [ { tags.output_bucket = "system"; } ];
      sensors = [ { tags.output_bucket = "system"; } ];
      systemd_units = [ { tags.output_bucket = "system"; } ];
    };
    processors = {
      topk = [
        {
          namepass = [ "procstat" ];
          period = 10;
          k = 5;
          fields = [
            "cpu_usage"
            "memory_rss"
          ];
          add_aggregate_fields = [
            "cpu_usage"
            "memory_rss"
          ];
        }
      ];
    };
  };
  systemd.services.telegraf.path = with pkgs; [
    lm_sensors
    procps # for pgrep
  ];
}
