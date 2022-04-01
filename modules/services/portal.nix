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
      default = "debug";
    };
    grpcServiceName = lib.mkOption {
      type = with lib.types; str;
      default = "63b13cf9fa5545ef912656fc769383dd";
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
      sops.secrets."portal/client-id".sopsFile = config.sops.secretsDir + /common.yaml;
      services.v2ray = {
        enable = true;
        configFile = config.sops.templates.portal-v2ray.path;
      };
      systemd.services.v2ray = {
        # TODO add a restart trigger
      };
    })

    (lib.mkIf cfg.server.enable {
      services.nginx.virtualHosts.${cfg.host} = {
        locations."/${cfg.grpcServiceName}/Tun".extraConfig = ''
          # if the request method is not POST for this location, return 404
          if ($request_method != "POST") {
            return 404;
          }

          grpc_socket_keepalive on;
          grpc_intercept_errors on;
          grpc_pass grpc://127.0.0.1:${toString cfg.server.internalPort};
          grpc_set_header Upgrade $http_upgrade;
          grpc_set_header Connection "upgrade";
          grpc_set_header Host $host;

          # show real IP in v2ray access.log
          grpc_set_header X-Real-IP $remote_addr;
          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };

      sops.templates.portal-v2ray.content = builtins.toJSON {
        log.loglevel = cfg.logLevel;
        inbounds = [
          {
            port = cfg.server.internalPort;
            protocol = "vmess";
            settings = {
              clients = [
                {
                  id = config.sops.placeholder."portal/client-id";
                  inherit (cfg) alterId;
                }
              ];
              disableInsecureEncryption = true;
            };
            streamSettings = {
              network = "grpc";
              grpcSettings = {
                serviceName = cfg.grpcServiceName;
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
      sops.templates.portal-v2ray.content =
        let
          basicConfig = {
            log.loglevel = cfg.logLevel;
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
                          id = config.sops.placeholder."portal/client-id";
                          inherit (cfg) alterId;
                        }
                      ];
                    }
                  ];
                };
                streamSettings = {
                  network = "grpc";
                  security = "tls";
                  grpcSettings = {
                    serviceName = cfg.grpcServiceName;
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
