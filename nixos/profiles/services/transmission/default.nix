{config, ...}: let
  rpcPort = config.ports.transmission-rpc;
in {
  services.transmission = {
    enable = true;
    openFirewall = true;
    credentialsFile = config.sops.templates."transmission-credentials".path;
    settings = {
      rpc-port = rpcPort;
      rpc-bind-address = "::";
      rpc-authentication-required = true;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
  };

  sops.templates."transmission-credentials".content = builtins.toJSON {
    rpc-username = config.sops.placeholder."transmission_username";
    rpc-password = config.sops.placeholder."transmission_password";
  };

  services.samba.shares.transmission = {
    "path" = "/var/lib/transmission/Downloads";
    "read only" = true;
    "browseable" = true;
    "comment" = "Transmission downloads";
  };

  sops.secrets."transmission_password".restartUnits = ["transmission.service"];
}
