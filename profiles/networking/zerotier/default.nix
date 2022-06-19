{ config, pkgs, ... }:

let
  stateDir = "/var/lib/zerotier-one";
  interfaceName = "zt0";
  hostName = config.networking.hostName;
  port = 9993;
  units = [
    "zerotierone-presetup.service"
    "zerotierone.service"
    "zerotierone-postsetup.service"
  ];
in
{
  services.zerotierone = {
    enable = true;
    inherit port;
  };
  systemd.services.zerotierone-presetup = {
    script = ''

      cp "${config.sops.secrets."hosts/value/${hostName}/zerotier_public_key".path}" "${stateDir}/identity.public"
      cp "${config.sops.secrets."hosts/value/${hostName}/zerotier_private_key".path}" "${stateDir}/identity.secret"

      mkdir -p "${stateDir}/networks.d"
      NETWORK_ID=$(cat "${config.sops.secrets."zerotier/main".path}")
      touch "${stateDir}/networks.d/$NETWORK_ID.conf"
      echo "$NETWORK_ID=${interfaceName}" > "${stateDir}/devicemap"
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
      Restart = "on-failure";
    };
    after = [ "zerotierone.service" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.zerotierone.requires = [
    "zerotierone-presetup.service"
    "zerotierone-postsetup.service"
  ];
  sops.secrets."zerotier/main" = {
    sopsFile = config.sops.secretsDir + /infrastructure.yaml;
    restartUnits = units;
  };
  sops.secrets."zerotier/moon" = {
    sopsFile = config.sops.secretsDir + /infrastructure.yaml;
    restartUnits = units;
  };
  sops.secrets."hosts/value/${hostName}/zerotier_public_key" = {
    sopsFile = config.sops.secretsDir + /terraform-outputs.yaml;
    restartUnits = units;
  };
  sops.secrets."hosts/value/${hostName}/zerotier_private_key" = {
    sopsFile = config.sops.secretsDir + /terraform-outputs.yaml;
    restartUnits = units;
  };

  networking.firewall.allowedTCPPorts = [
    config.services.zerotierone.port
  ];
}
