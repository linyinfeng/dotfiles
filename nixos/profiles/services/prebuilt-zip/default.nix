{lib, ...}: let
  explicitRickRolls = [
    "nixos-minimal-23.05pre485269.e6e389917a8-aarch64-linux.prebuilt.zip"
    "unzip-6.0-amd64-linux.prebuilt.zip"
  ];
in {
  services.nginx.virtualHosts."*.prebuilt.zip" = {
    # actually forced because of HSTS
    addSSL = true;
    useACMEHost = "prebuilt-zip";
    locations."/".extraConfig = ''
      return 302 http://prebuilt.zip/$host$request_uri;
    '';
  };
  services.nginx.virtualHosts."prebuilt.zip" = {
    forceSSL = true;
    useACMEHost = "prebuilt-zip";
    locations."/".extraConfig = ''
      return 302 https://www.youtube.com/watch?v=dQw4w9WgXcQ;
    '';
  };
  security.acme.certs."prebuilt-zip" = {
    domain = "prebuilt.zip";
    extraDomainNames =
      [
        "*.prebuilt.zip"
      ]
      ++ lib.lists.map (n: "*.${toString n}.prebuilt.zip") (lib.range 0 9)
      ++ explicitRickRolls;
  };
}
