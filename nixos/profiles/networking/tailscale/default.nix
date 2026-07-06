{ config, lib, ... }:
let
  inherit (config.networking) useNetworkd;
  cfg = config.services.tailscale;
  interfaceName = "tailscale0";
  exitNode = config.networking.hostsData.indexed;
  inherit (config.lib.self) data;
in
lib.mkMerge [
  { services.tailscale.enable = lib.mkDefault config.networking.hostsData.indexed; }
  (lib.mkIf cfg.enable {
    services.tailscale = {
      port = config.ports.tailscale;
      inherit interfaceName;
      authKeyFile = config.sops.secrets."tailscale_tailnet_key".path;
      extraSetFlags = lib.optional exitNode "--advertise-exit-node" ++ [
        "--accept-dns"
      ];
    };
    passthru.tailscaleInterfaceName = interfaceName;
    systemd.services.tailscaled = {
      serviceConfig = {
        LogLevelMax = "notice"; # simply suppress all logs from tailscaled
      };
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
  {
    systemd.network.networks."40-tailscale-override" = lib.mkIf useNetworkd {
      matchConfig = {
        Name = cfg.interfaceName;
      };
      linkConfig = {
        RequiredForOnline = false;
        ActivationPolicy = "manual";
      };
      networkConfig = {
        # tailscale is a layer 3 VPN
        # do not advertise or configure any IP addresses on the tailscale interface through systemd-networkd
        LinkLocalAddressing = "no";
        IPv6AcceptRA = "no";
        DHCP = "no";
        # DNS configuration only
        DNS = [ "100.100.100.100" ];
        Domains = [ "~${data.tailscale_tailnet_domain}" ];
      };
    };
  }
]
