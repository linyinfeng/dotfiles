{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.portal;
in
{
  options.services.portal = {
    host = lib.mkOption { type = with lib.types; str; };
    nginxVirtualHost = lib.mkOption { type = with lib.types; str; };
    logLevel = lib.mkOption {
      type = with lib.types; str;
      default = "Info";
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
      ports.http = lib.mkOption {
        type = with lib.types; int;
        default = 8080;
      };
      ports.socks = lib.mkOption {
        type = with lib.types; int;
        default = 1080;
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
      sops.secrets."portal_client_id" = {
        terraformOutput.enable = true;
        restartUnits = [ "v2ray-portal.service" ];
      };
      systemd.packages = [ pkgs.v2ray ];
      systemd.services.v2ray-portal = {
        serviceConfig = {
          ExecStart = [ "${pkgs.v2ray}/bin/v2ray run --config %d/config --format jsonv5" ];
          LoadCredential = [ "config:${config.sops.templates.portal-v2ray.path}" ];
          DynamicUser = true;
          CapabilityBoundingSet = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          AmbientCapabilities = [
            "CAP_NET_ADMIN"
            "CAP_NET_BIND_SERVICE"
          ];
          NoNewPrivileges = true;
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        restartTriggers = [ config.sops.templates.portal-v2ray.content ];
      };
    })

    (lib.mkIf cfg.server.enable {
      services.nginx.virtualHosts.${cfg.nginxVirtualHost} = {
        locations."/${cfg.grpcServiceName}/Tun".extraConfig = ''
          # if the request method is not POST for this location, return 404
          if ($request_method != "POST") {
            return 404;
          }

          grpc_socket_keepalive on;
          grpc_intercept_errors on;
          grpc_pass grpc://127.0.0.1:${toString cfg.server.internalPort};

          # show real IP in v2ray access.log
          grpc_set_header X-Real-IP $remote_addr;
          grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };

      sops.templates.portal-v2ray.content = builtins.toJSON {
        log = {
          access = {
            type = "Console";
            level = cfg.logLevel;
          };
          error = {
            type = "Console";
            level = cfg.logLevel;
          };
        };
        inbounds = [
          {
            protocol = "trojan";
            settings = {
              users = [ config.sops.placeholder."portal_client_id" ];
              packetEncoding = "Packet"; # full cone
            };
            port = cfg.server.internalPort;
            streamSettings = {
              transport = "grpc";
              transportSettings.serviceName = cfg.grpcServiceName;
            };
          }
        ];
        outbounds = [ { protocol = "freedom"; } ];
      };
    })

    (lib.mkIf cfg.client.enable {
      sops.templates.portal-v2ray.content =
        let
          basicConfig = {
            log = {
              access = {
                type = "Console";
                level = cfg.logLevel;
              };
              error = {
                type = "Console";
                level = cfg.logLevel;
              };
            };
            inbounds = [
              {
                protocol = "socks";
                settings = {
                  udpEnabled = true;
                };
                port = cfg.client.ports.socks;
                listen = "::1";
              }
              {
                protocol = "http";
                port = cfg.client.ports.http;
                listen = "::1";
              }
            ];
            outbounds = [
              {
                protocol = "trojan";
                settings = {
                  address = cfg.host;
                  port = config.ports.https;
                  password = config.sops.placeholder."portal_client_id";
                };
                streamSettings = {
                  transport = "grpc";
                  transportSettings.serviceName = cfg.grpcServiceName;
                  security = "tls";
                };
              }
            ];
          };
        in
        builtins.toJSON (lib.recursiveUpdate basicConfig cfg.client.extraV2rayConfig);
    })
  ];
}
