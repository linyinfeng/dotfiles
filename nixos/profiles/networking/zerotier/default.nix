{config, ...}: let
  stateDir = "/var/lib/zerotier-one";
  interfaceName = "zt0";
  port = config.ports.zerotier;
  units = [
    "zerotierone-presetup.service"
    "zerotierone.service"
  ];
in {
  services.zerotierone = {
    enable = true;
    inherit port;
  };
  passthru.zerotierInterfaceName = interfaceName;
  systemd.services.zerotierone-presetup = {
    script = ''
      echo "create directory"
      mkdir -p "${stateDir}"

      echo "setting up identity files..."
      cp "${config.sops.secrets."zerotier_public_key".path}" "${stateDir}/identity.public"
      cp "${config.sops.secrets."zerotier_private_key".path}" "${stateDir}/identity.secret"

      echo "setting up network interface..."
      mkdir -p "${stateDir}/networks.d"
      NETWORK_ID=$(cat "${config.sops.secrets."zerotier_network_id".path}")
      touch "${stateDir}/networks.d/$NETWORK_ID.conf"
      echo "$NETWORK_ID=${interfaceName}" > "${stateDir}/devicemap"

      echo "cleaning up moon..."
      rm -rf "${stateDir}/moons.d"

      echo "setting up moon..."
      mkdir -p "${stateDir}/moons.d"
      FILENAME=$(cat ${config.sops.secrets."zerotier_moon_filename".path})
      cat ${config.sops.secrets."zerotier_moon_content_base64".path} |\
        base64 --decode \
        > "${stateDir}/moons.d/$FILENAME"
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    before = ["zerotierone.service"];
    wantedBy = ["multi-user.target"];
  };
  systemd.services.zerotierone.requires = [
    "zerotierone-presetup.service"
  ];
  sops.secrets."zerotier_network_id" = {
    terraformOutput.enable = true;
    restartUnits = units;
  };
  sops.secrets."zerotier_moon_filename" = {
    terraformOutput = {
      enable = true;
      yqPath = ".zerotier_moon.value.filename";
    };
    restartUnits = units;
  };
  sops.secrets."zerotier_moon_content_base64" = {
    terraformOutput = {
      enable = true;
      yqPath = ".zerotier_moon.value.content_base64";
    };
    restartUnits = units;
  };
  sops.secrets."zerotier_public_key" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    restartUnits = units;
  };
  sops.secrets."zerotier_private_key" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    restartUnits = units;
  };

  networking.firewall.allowedUDPPorts = [
    config.services.zerotierone.port
  ];
  networking.firewall.allowedTCPPorts = [
    config.services.zerotierone.port
  ];

  services.zerotierone.localConf.settings.interfacePrefixBlacklist = [
    "tailscale"
    # mesh interfaces
    "mesh"
    "dn42"
    "as198764"
  ];

  networking.networkmanager.unmanaged = [interfaceName];
}
