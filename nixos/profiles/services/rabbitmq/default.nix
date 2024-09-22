{ config, ... }:
{
  services.rabbitmq = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = config.ports.rabbitmq;
    managementPlugin = {
      enable = true;
      port = config.ports.rabbitmq-management;
    };
  };
}
