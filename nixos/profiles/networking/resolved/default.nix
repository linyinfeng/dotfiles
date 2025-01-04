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
      # At the time of September 2023, systemd upstream advise to disable DNSSEC by default as the current code is not
      # robust enough to deal with “in the wild” non-compliant servers, which will usually give you a broken bad
      # experience in addition of insecure.
      # dnssec = "allow-downgrade";
      dnssec = "false";
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
