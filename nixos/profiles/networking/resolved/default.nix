{
  config,
  lib,
  ...
}: let
  dnsServers = [
    # Cloudflare public DNS
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
    # Google public DNS
    "8.8.8.8"
    "8.8.4.4"
    "2001:4860:4860::8888"
    "2001:4860:4860::8844"
    # TUNA DNS666
    "2001:da8::666"
    # TWNIC
    "101.101.101.101"
    "101.102.103.104"
  ];
in
  lib.mkMerge [
    {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade";
        llmnr = "true";
        fallbackDns = [];
        # TODO not stable
        # extraConfig = ''
        #   DNS=${lib.concatStringsSep " " dnsServers}
        #   DNSOverTLS=yes
        # '';
      };
      networking.firewall.allowedUDPPorts = [
        5353
      ];
    }
    (lib.mkIf config.services.avahi.enable {
      services.resolved.extraConfig = ''
        MulticastDNS=resolve
      '';
    })
  ]
