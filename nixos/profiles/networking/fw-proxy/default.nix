{
  config,
  lib,
  ...
}: let
  cfg = config.networking.fw-proxy;
  inherit (config.networking) hostName;
in {
  networking.fw-proxy = {
    enable = true;
    ports = {
      mixed = config.ports.proxy-mixed;
      tproxy = config.ports.proxy-tproxy;
      controller = config.ports.sing-box-controller;
    };
    tproxy = {
      enable = lib.mkDefault true;
      slice = "tproxy";
      bypassSlice = "bypasstproxy";
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
    profiles = {
      main.urlFile = config.sops.secrets."sing-box/main".path;
      alternative.urlFile = config.sops.secrets."sing-box/alternative".path;
    };
    externalController = {
      expose = true;
      virtualHost = "${hostName}.*";
      location = "/sing-box/";
      secretFile = config.sops.secrets."fw_proxy_external_controller_secret".path;
    };
  };

  sops.secrets."fw_proxy_external_controller_secret" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = ["sing-box-auto-update.service"];
  };
  sops.secrets."sing-box/main" = {
    sopsFile = config.sops-file.get "common.yaml";
    restartUnits = ["sing-box-auto-update.service"];
  };
  sops.secrets."sing-box/alternative" = {
    sopsFile = config.sops-file.get "common.yaml";
    restartUnits = ["sing-box-auto-update.service"];
  };

  networking.fw-proxy.auto-update = {
    enable = true;
    service = "main";
  };

  systemd.services.nix-daemon.environment = cfg.environment;
}
