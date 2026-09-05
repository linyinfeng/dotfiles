{ config, lib, ... }:
{
  sops.secrets."frp_token" = {
    terraformOutput.enable = true;
    mode = "0444"; # frp runs as DynamicUser
    restartUnits = [ "frp.service" ];
  };

  services.frp.instances."" = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = "xps8930-frp.li7g.com";
      serverPort = 443;
      transport.protocol = "websocket";
      auth.tokenSource = {
        type = "file";
        file.path = config.sops.secrets."frp_token".path;
      };
      log.level = "info";
      proxies = [
        {
          name = "ssh";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = config.ports.ssh;
          remotePort = config.ports.frp-ssh;
        }
      ];
    };
  };
}
