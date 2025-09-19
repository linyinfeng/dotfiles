{ config, lib, ... }:
let
  dnsServers = [
    "[${config.lib.self.data.dn42_anycast_dns_v6}]:${toString config.ports.dns-over-tls}#dns.li7g.com"
  ];
in
lib.mkMerge [
  {
    services.resolved = {
      enable = true;
      llmnr = "true";
      # dnssec = "allow-downgrade";
      # dnsovertls = "opportunistic";
      fallbackDns = dnsServers;
      domains = [ "li7g.com" ];
    };
    networking.firewall.allowedUDPPorts = [ 5353 ];
  }
  (lib.mkIf config.services.avahi.enable {
    services.resolved.extraConfig = ''
      MulticastDNS=resolve
    '';
  })
]
