{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.telegraf-system.diskMountPoints = lib.mkOption {
    type = with lib.types; listOf str;
    description = ''
      Mount points to collect `disk` metrics for. One entry per distinct
      filesystem is enough: subvolumes of the same btrfs pool report the same
      capacity, and every mount point costs one series per `disk` field.
    '';
  };
  config = {
    assertions = [
      {
        assertion = config.services.telegraf-system.diskMountPoints != [ ];
        message = ''
          services.telegraf-system.diskMountPoints is not set on this host.
          List the mount points to collect disk metrics for, e.g.
          [ "/nix" "/boot" ]; one entry per distinct filesystem is enough.
        '';
      }
    ];
    services.telegraf.extraConfig.outputs.influxdb = [
      (config.lib.telegraf.mkMainInfluxdbOutput "system")
    ];
    services.telegraf.extraConfig = {
      inputs = {
        cpu = [
          {
            # 10 fields x (cores + total); the total is all the dashboards need
            percpu = false;
            totalcpu = true;
            collect_cpu_time = false;
            report_active = false;
            tags.output_bucket = "system";
          }
        ];
        procstat = [
          {
            pattern = ".*";
            # cmdline grows with every argument of every process; pid keeps the
            # series unique per process and is bounded by topk
            tag_with = [ "pid" ];
            fieldinclude = [
              "cpu_usage"
              "memory_rss"
            ];
            tags.output_bucket = "system";
          }
        ];
        disk = [
          {
            mount_points = config.services.telegraf-system.diskMountPoints;
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
        net = [
          { tags.output_bucket = "system"; }
        ];
        processes = [ { tags.output_bucket = "system"; } ];
        swap = [ { tags.output_bucket = "system"; } ];
        system = [ { tags.output_bucket = "system"; } ];
        sensors = [ { tags.output_bucket = "system"; } ];
        systemd_units = [
          {
            # only the units that are failed or have a job pending
            tagpass.active = [
              "failed"
              "activating"
              "deactivating"
            ];
            tags.output_bucket = "system";
          }
        ];
      };
      processors = {
        topk = [
          {
            namepass = [ "procstat" ];
            period = 10;
            k = 5;
            group_by = [ "pid" ];
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
  };
}
