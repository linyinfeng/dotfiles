{ config, pkgs, ... }:

let
  stateDir = "/var/lib/zerotier-one";
  interfaceName = "zt0";
  port = 9993;
in
{
  services.zerotierone = {
    enable = true;
    inherit port;
  };
  systemd.services.zerotierone-presetup = {
    script = ''
      mkdir -p "${stateDir}/networks.d"

      NETWORK_ID=$(cat "${config.sops.secrets."zerotier/main".path}")
      touch "${stateDir}/networks.d/''${NETWORK_ID}.conf"
      echo "''${NETWORK_ID}=${interfaceName}" > "${stateDir}/devicemap"
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    before = [ "zerotierone.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.zerotierone-postsetup = {
    script = ''
      moon_id=$(cat ${config.sops.secrets."zerotier/moon".path})
      echo "moon: $moon_id"
      zerotier-cli orbit $moon_id $moon_id
    '';
    path = [
      config.services.zerotierone.package
    ];
    serviceConfig = {
      # delay before start
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
      Type = "oneshot";
      RemainAfterExit = true;
    };
    after = [ "zerotierone.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.zerotierone.requires = [
    "zerotierone-presetup.service"
    "zerotierone-postsetup.service"
  ];
  sops.secrets."zerotier/main".sopsFile = config.sops.secretsDir + /infrastructure.yaml;
  sops.secrets."zerotier/moon".sopsFile = config.sops.secretsDir + /infrastructure.yaml;

  networking.firewall.allowedTCPPorts = [
    config.services.zerotierone.port
  ];
}
