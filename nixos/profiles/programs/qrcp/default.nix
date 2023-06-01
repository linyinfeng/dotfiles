{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    qrcp
  ];
  environment.shellAliases = {
    qrcp = "qrcp --port ${toString config.ports.qrcp}";
  };
  networking.firewall.allowedTCPPorts = [
    config.ports.qrcp
  ];
}
