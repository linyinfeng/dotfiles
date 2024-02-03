{
  config,
  options,
  lib,
  ...
}: let
  cfg = config.networking.fw-proxy;
  inherit (config.networking) hostName;
  profiles = ["main" "exclusive" "alternative"];
in
  lib.mkMerge [
    {
      networking.fw-proxy = {
        enable = true;
        ports = {
          mixed = config.ports.proxy-mixed;
          tproxy = config.ports.proxy-tproxy;
          controller = config.ports.sing-box-controller;
        };
        noProxyPattern =
          options.networking.fw-proxy.noProxyPattern.default
          ++ [
            "*.ts.li7g.com"
            "*.zt.li7g.com"
            "*.dn42.li7g.com"
          ];
        tproxy = {
          enable = lib.mkDefault true;
          routingTable = config.routingTables.fw-proxy;
          rulePriority = config.routingPolicyPriorities.fw-proxy;
        };
        downloadedConfigPreprocessing = ''
          # if [ $($jq --raw-output '.profile_name' "$profile_info_file") = "alternative" ]; then
          #   $yq --inplace 'del(.proxies[] | select(.name != "*IEPL*"))' "$downloaded_config"
          # fi
        '';
        configPreprocessing = ''
          jq 'del(.log) | del(.inbounds) | del(.experimental.clash_api)' "$raw_config" |\
            sponge "$raw_config"
        '';
        mixinConfig = {
          log = {
            level = "info";
            timestamp = false; # added by journald
          };
        };
        profiles = lib.listToAttrs (lib.lists.map (p:
          lib.nameValuePair p {
            urlFile = config.sops.secrets."sing-box/${p}".path;
          })
        profiles);
        externalController = {
          expose = true;
          virtualHost = "${hostName}.*";
          location = "/sing-box/";
          secretFile = config.sops.secrets."fw_proxy_external_controller_secret".path;
        };
      };

      sops.secrets."fw_proxy_external_controller_secret" = {
        terraformOutput.enable = true;
        restartUnits = ["sing-box-auto-update.service"];
      };

      networking.fw-proxy.auto-update = {
        enable = true;
        service = "main";
      };

      systemd.services.nix-daemon.environment = cfg.environment;
    }
    {
      sops.secrets = lib.listToAttrs (lib.lists.map (p:
        lib.nameValuePair "sing-box/${p}" {
          sopsFile = config.sops-file.get "common.yaml";
          restartUnits = ["sing-box-auto-update.service"];
        })
      profiles);
    }
  ]
