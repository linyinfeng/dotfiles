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
      dnssec = "allow-downgrade";
      llmnr = "true";
      extraConfig = lib.mkIf config.networking.mesh.enable ''
        DNS=${lib.concatStringsSep " " dnsServers}
        # link specific servers may not support dns over tls
        DNSOverTLS=opportunistic
        Domains=~.
      '';
    };
    networking.firewall.allowedUDPPorts = [ 5353 ];
  }
  (lib.mkIf config.services.avahi.enable {
    services.resolved.extraConfig = ''
      MulticastDNS=resolve
    '';
  })
]
