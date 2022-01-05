{ config, ... }:

let
  stateDir = "/var/lib/zerotier-one";
  interfaceName = "zt0";
in
{
  services.zerotierone.enable = true;
  systemd.services.zerotierone-setup = {
    script = ''
      mkdir -p "${stateDir}/networks.d"

      NETWORK_ID=$(cat "${config.sops.secrets."zerotier/main".path}")
      touch "${stateDir}/networks.d/''${NETWORK_ID}.conf"
      echo "''${NETWORK_ID}=${interfaceName}" > /var/lib/zerotier-one/devicemap
    '';
    serviceConfig = {
      Type = "oneshot";
    };
    before = [ "zerotierone.service" ];
  };
  systemd.services.zerotierone.requires = [ "zerotierone-setup.service" ];
  sops.secrets."zerotier/main" = { };

  environment.global-persistence.directories = [
    stateDir
  ];

  networking.firewall.trustedInterfaces = [
    interfaceName
  ];
}
