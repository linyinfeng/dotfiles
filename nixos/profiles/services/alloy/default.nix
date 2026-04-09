{ config, ... }:
let
  inherit (config.lib.self.data) loki_username loki_host;
in
{
  services.alloy = {
    enable = true;
    extraFlags = [ ];
    environmentFile = config.sops.templates."alloy-env".path;
  };
  environment.etc."alloy/config.alloy".text = ''
    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal_priority"]
        target_label  = "priority"
      }

      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__systemd_user_unit"]
        target_label  = "user_unit"
      }

      rule {
        source_labels = ["__journal__boot_id"]
        target_label  = "boot_id"
      }

      rule {
        source_labels = ["__journal__comm"]
        target_label  = "command"
      }
    }

    loki.source.journal "journal" {
      max_age       = "6h0m0s"
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.default.receiver]
      labels        = {
        host = "parrot",
        job  = "systemd-journal",
      }
    }

    loki.write "default" {
      endpoint {
        url = "https://${loki_host}/loki/api/v1/push"

        basic_auth {
          username = "${loki_username}"
          password = sys.env("LOKI_PASSWORD")
        }
      }
      external_labels = {}
    }
  '';
  sops.templates."alloy-env".content = ''
    LOKI_PASSWORD=${config.sops.placeholder."loki_password"}
  '';
  sops.secrets."loki_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "alloy.service" ];
  };
}
