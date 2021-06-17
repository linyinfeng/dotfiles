{ ... }:

{
  services.transmission = {
    enable = true;
    openFirewall = true;
  };

  services.samba.shares.transmission = {
    "path" = "/var/lib/transmission/Downloads";
    "read only" = true;
    "browseable" = true;
    "comment" = "Dransmission downloads";
  };
}
