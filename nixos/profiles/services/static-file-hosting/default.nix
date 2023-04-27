{...}: {
  services.nginx.virtualHosts."static.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".root = "/var/www/static";
    extraConfig = ''
      autoindex on;
    '';
  };
  environment.global-persistence.directories = [
    "/var/www/static"
  ];
}
