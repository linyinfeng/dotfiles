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
      settings.Resolve = {
        Domains = [ "li7g.com" ];
        LLMNR = true;
        FallbackDNS = dnsServers;
        # DNSSEC = "allow-downgrade";
        # DNSOverTLS = "opportunistic";
      };
    };
    networking.firewall.allowedUDPPorts = [ 5353 ];
  }
  (lib.mkIf config.services.avahi.enable {
    services.resolved.settings.Resolve = {
      MulticastDNS = "resolve";
    };
  })
]
