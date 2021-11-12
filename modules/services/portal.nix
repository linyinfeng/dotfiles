{ config, lib, ... }:

let
  cfg = config.services.portal;
in
{
  options.services.portal = {
    host = lib.mkOption {
      type = with lib.types; str;
    };
    alterId = lib.mkOption {
      type = with lib.types; int;
      default = 0;
    };
    logLevel = lib.mkOption {
      type = with lib.types; str;
      default = "info";
    };
    path = lib.mkOption {
      type = with lib.types; str;
      default = "/63b13cf9-fa55-45ef-9126-56fc769383dd";
    };
    client = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = false;
      };
      port = lib.mkOption {
        type = with lib.types; int;
        default = 8080;
      };
      extraV2rayConfig = lib.mkOption {
        type = with lib.types; attrs;
        default = { };
      };
    };
    server = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = false;
      };
      internalPort = lib.mkOption {
        type = with lib.types; int;
        default = 1080;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (with cfg; server.enable || client.enable) {
      age.secrets.portal-client-id.file = config.age.secrets-directory + /portal-client-id.age;
      services.v2ray = {
        enable = true;
        configFile = config.age.templates.portal-v2ray.path;
      };
      systemd.services.v2ray = {
        environment = {
          "v2ray.vmess.aead.forced" = "true";
        };
        # TODO add a restart trigger
      };
    })
    (lib.mkIf cfg.server.enable {
      services.nginx.virtualHosts.${cfg.host} = {
        addSSL = true;
        locations.${cfg.path}.extraConfig = ''
          if ($http_upgrade != "websocket") { # Return 404 error when WebSocket upgrading negotiate failed
            return 404;
          }
          proxy_redirect off;
          proxy_pass http://localhost:${toString cfg.server.internalPort};
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          # Show real IP in v2ray access.log
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };

      age.templates.portal-v2ray.content = builtins.toJSON {
        log.loglevel = cfg.logLevel;
        inbounds = [
          {
            port = cfg.server.internalPort;
            protocol = "vmess";
            settings = {
              clients = [
                {
                  id = config.age.placeholder.portal-client-id;
                  inherit (cfg) alterId;
                }
              ];
              disableInsecureEncryption = true;
            };
            streamSettings = {
              network = "ws";
              wsSettings = {
                inherit (cfg) path;
              };
            };
          }
        ];
        outbounds = [
          {
            protocol = "freedom";
          }
        ];
      };
    })
    (lib.mkIf cfg.client.enable {
      age.templates.portal-v2ray.content =
        let
          basicConfig = {
            inbounds = [
              {
                port = cfg.client.port;
                listen = "127.0.0.1";
                protocol = "socks";
                settings = {
                  auth = "noauth";
                  udp = true;
                };
              }
            ];
            outbounds = [
              {
                protocol = "vmess";
                settings = {
                  vnext = [
                    {
                      address = cfg.host;
                      port = 443;
                      users = [
                        {
                          id = config.age.placeholder.portal-client-id;
                          inherit (cfg) alterId;
                        }
                      ];
                    }
                  ];
                };
                streamSettings = {
                  network = "ws";
                  security = "tls";
                  wsSettings = {
                    path = cfg.path;
                  };
                };
                mux = {
                  enabled = false;
                  # mux as much as possible
                  concurrency = 1024;
                };
              }
            ];
          };
        in
        builtins.toJSON (lib.recursiveUpdate basicConfig cfg.client.extraV2rayConfig);
    })
  ];
}
