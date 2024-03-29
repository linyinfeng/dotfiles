{ config, lib, ... }:
let
  cfg = config.services.tailscale;
  interfaceName = "tailscale0";
in
lib.mkMerge [
  { services.tailscale.enable = lib.mkDefault config.networking.hostsData.indexed; }
  (lib.mkIf cfg.enable {
    services.tailscale = {
      port = config.ports.tailscale;
      inherit interfaceName;
    };
    passthru.tailscaleInterfaceName = interfaceName;
    systemd.services.tailscale-setup = {
      script = ''
        sleep 10

        if tailscale status; then
          echo "tailscale already up, skip"
        else
          echo "tailscale down, login using auth key"
          tailscale up --auth-key "file:${config.sops.secrets."tailscale_tailnet_key".path}"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.services.tailscale.package ];
      after = [ "tailscaled.service" ];
      requiredBy = [ "tailscaled.service" ];
    };
    systemd.services.tailscaled.environment = {
      # use custom patch: tailscale-excluded-interface-prefixes.patch
      # exclusion of "zt" is already hardcoded by tailscale
      # so "zt" is included just for clearness
      TS_EXCLUDED_INTERFACE_PREFIXES = lib.concatStringsSep " " [
        "zt"
        # mesh interfaces
        "mesh"
        "dn42"
      ];
    };
    sops.secrets."tailscale_tailnet_key" = {
      terraformOutput.enable = true;
      restartUnits = [ "tailscale-setup.service" ];
    };
    # no need to open ports
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
    networking.firewall.checkReversePath = false;
    networking.networkmanager.unmanaged = [ interfaceName ];
  })
]
