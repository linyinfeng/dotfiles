{ config, lib, ... }:

{
  services.ollama = {
    enable = true;
    port = config.ports.ollama;
    environmentVariables = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
  };
  environment.variables = {
    inherit (config.systemd.services.ollama.environment) OLLAMA_HOST;
  };
}
