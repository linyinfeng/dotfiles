{...}: {
  services.nginx.virtualHosts."prebuilt.zip" = {
    serverAliases = ["*.prebuilt.zip"];
    forceSSL = true;
    useACMEHost = "prebuilt-zip";
    locations."/".extraConfig = ''
      return 302 https://www.youtube.com/watch?v=dQw4w9WgXcQ;
    '';
  };
  security.acme.certs."prebuilt-zip" = {
    domain = "prebuilt.zip";
    extraDomainNames = [
      "*.prebuilt.zip"
    ];
  };
}
