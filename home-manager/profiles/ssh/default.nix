{ config, ... }:
let
  inherit (config.lib.self) data;
in
{
  programs.ssh = {
    enable = true;
    # The legacy default block only restates OpenSSH's own defaults, so keep
    # the file down to the settings that actually differ.
    enableDefaultConfig = false;
    settings."*" = {
      ControlMaster = "auto";
      ControlPath = "~/.ssh/control-master-%r@%h:%p";
      ControlPersist = "10m";
    };
  };

  programs.opkssh = {
    enable = true;
    settings = {
      default_provider = "zitadel";
      providers = [
        {
          alias = "zitadel";
          issuer = data.zitadel_issuer;
          client_id = data.zitadel_opkssh_client_id;
          scopes = "openid profile email";
          # Default loopback callbacks used by opkssh.
          redirect_uris = [
            "http://localhost:3000/login-callback"
            "http://localhost:10001/login-callback"
            "http://localhost:11110/login-callback"
          ];
        }
      ];
    };
  };
}
