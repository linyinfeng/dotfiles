{ ... }:

{
  services.nginx.virtualHosts."static.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".root = "/var/www/static";
  };
}
