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
      # dns.li7g.com supports DNSSEC and DoT property
      dnssec = "true";
      dnsovertls = "opportunistic";
    };
    networking.firewall.allowedUDPPorts = [ 5353 ];
  }
  (lib.mkIf config.services.avahi.enable {
    services.resolved.extraConfig = ''
      DNS=${lib.concatStringsSep " " dnsServers}
      Domains=~. li7g.com
      MulticastDNS=resolve
    '';
  })
]
