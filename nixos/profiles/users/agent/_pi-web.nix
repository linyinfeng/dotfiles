{ config, pkgs, ... }:
let
  runtimeInputs =
    (with pkgs; [
      pkgs.nodejs
      pkgs.python3
      pkgs.gnumake
      pkgs.gcc
    ])
    ++ config.home-manager.users.agent.programs.pi-coding-agent.extraPackages;
  piWeb = pkgs.writeShellApplication {
    name = "pi-web";
    inherit runtimeInputs;
    text = ''
      set -euo pipefail
      ST="''${STATE_DIRECTORY:-$HOME/.local/state/pi-web}"
      mkdir -p "$ST"
      cd "$ST"
      if [ ! -d node_modules/@jmfederico/pi-web ]; then
        [ -f package.json ] || echo '{"name":"pi-web","private":true}' > package.json
        echo "pi-web-service: installing pi-web into $ST ..."
        npm install @jmfederico/pi-web
      fi
      echo "pi-web-service: starting pi-web ..."
      exec node node_modules/@jmfederico/pi-web/dist/server/index.js
    '';
  };

  piWebSessiond = pkgs.writeShellApplication {
    name = "pi-web-sessiond";
    inherit runtimeInputs;
    text = ''
      set -euo pipefail
      ST="''${STATE_DIRECTORY:-$HOME/.local/state/pi-web}"
      mkdir -p "$ST"
      cd "$ST"
      if [ ! -d node_modules/@jmfederico/pi-web ]; then
        [ -f package.json ] || echo '{"name":"pi-web","private":true}' > package.json
        echo "pi-web-sessiond: installing pi-web into $ST ..."
        npm install @jmfederico/pi-web
      fi
      echo "pi-web-sessiond: starting session daemon ..."
      exec node node_modules/@jmfederico/pi-web/dist/server/sessiond.js
    '';
  };
in
{
  home-manager.users.agent = { osConfig, lib, ... }: {
    systemd.user.services.pi-web = {
      Unit = {
        Description = "PI WEB — web UI for the Pi coding agent";
        After = [
          "network-online.target"
          "pi-web-sessiond.service"
        ];
        Wants = [
          "network-online.target"
          "pi-web-sessiond.service"
        ];
      };
      Service = {
        ExecStart = lib.getExe piWeb;
        Restart = "on-failure";
        RestartSec = "5";
        StateDirectory = "pi-web";
        Environment = lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.stringEnvironment;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.services.pi-web-sessiond = {
      Unit = {
        Description = "PI WEB — session daemon";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = lib.getExe piWebSessiond;
        Restart = "on-failure";
        RestartSec = "5";
        StateDirectory = "pi-web";
        Environment = lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.stringEnvironment;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.file.".config/pi-web/config.json".text = builtins.toJSON {
      host = "::1";
      port = config.ports.pi-web;
      allowedHosts = true;
    };
  };

  services.nginx.virtualHosts."pi-web.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.pi-web}";
      extraConfig = ''
        auth_basic "pi-web";
        auth_basic_user_file ${config.sops.templates."pi-web-auth-file".path};
      '';
    };
  };

  systemd.services.nginx.restartTriggers = [ config.sops.templates."pi-web-auth-file".file ];
  sops.templates."pi-web-auth-file" = {
    content = ''
      ${config.sops.placeholder."pi_web_username"}:${config.sops.placeholder."pi_web_hashed_password"}
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."pi_web_username" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
  sops.secrets."pi_web_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
}
