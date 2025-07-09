{ config, lib, ... }:
let
  cfg = config.services.tailscale;
  interfaceName = "tailscale0";
  exitNode = config.networking.hostsData.indexed;
in
lib.mkMerge [
  { services.tailscale.enable = lib.mkDefault config.networking.hostsData.indexed; }
  (lib.mkIf cfg.enable {
    services.tailscale = {
      port = config.ports.tailscale;
      inherit interfaceName;
    };
    passthru.tailscaleInterfaceName = interfaceName;
    systemd.services.tailscaled = {
      serviceConfig = {
        LogLevelMax = "notice"; # simply suppress all logs from tailscaled
      };
    };
    systemd.services.tailscale-setup = {
      script = ''
        sleep 10

        if tailscale status; then
          echo "tailscale already up, skip"
        else
          echo "tailscale down, login using auth key"
          tailscale up --reset \
            --auth-key "file:${config.sops.secrets."tailscale_tailnet_key".path}" \
            ${lib.optionalString exitNode "--advertise-exit-node"}
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
