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
      default = "info";
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
        restartUnits = [ "xray-portal.service" ];
      };
      systemd.packages = with pkgs; [ xray ];
      systemd.services.xray-portal = {
        serviceConfig = {
          ExecStart = "${pkgs.xray}/bin/xray run --config %d/config.json";
          LoadCredential = [ "config.json:${config.sops.templates.portal-xray.path}" ];
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
        restartTriggers = [ config.sops.templates.portal-xray.content ];
      };
      sops.secrets."xray_id_yinfeng" = {
        terraformOutput.enable = true;
        restartUnits = [
          "xray-portal.service"
        ];
      };
      sops.secrets."xray_id_guest" = {
        terraformOutput.enable = true;
        restartUnits = [
          "xray-portal.service"
        ];
      };
      sops.secrets."xray_service_name" = {
        terraformOutput.enable = true;
        restartUnits = [
          "nginx.service"
          "xray-portal.service"
        ];
      };
      sops.secrets."xray_vless_encryption" = {
        predefined.enable = true;
        restartUnits = [
          "xray-portal.service"
        ];
      };
      sops.secrets."xray_vless_decryption" = {
        predefined.enable = true;
        restartUnits = [
          "xray-portal.service"
        ];
      };
    })

    (lib.mkIf cfg.server.enable {
      systemd.services.nginx.serviceConfig = {
        StateDirectory = "nginx";
        ExecStartPre = lib.mkBefore [
          "${lib.getExe' pkgs.coreutils "cp"} %d/nginx-xray.conf %S/nginx/nginx-xray.conf"
          "${lib.getExe' pkgs.coreutils "chmod"} 600 %S/nginx/nginx-xray.conf"
        ];
        LoadCredential = [
          "nginx-xray.conf:${config.sops.templates.nginx-xray.path}"
        ];
        RestartTriggers = [ config.sops.templates.nginx-xray.content ];
      };
      services.nginx.virtualHosts.${cfg.nginxVirtualHost}.extraConfig = ''
        include /var/lib/nginx/nginx-xray.conf;
      '';
      sops.templates.nginx-xray.content = ''
        location /${config.sops.placeholder."xray_service_name"} {
          ${if cfg.logLevel == "debug" then "" else "access_log off;"}
          proxy_pass http://[::1]:${toString config.ports.portal-internal};
        }
      '';
      sops.templates.portal-xray.content = builtins.toJSON {
        log = {
          loglevel = cfg.logLevel;
        };
        dns = {
          servers = [
            "https+local://1.1.1.1/dns-query"
            "localhost"
          ];
        };
        routing = {
          domainStrategy = "IPIfNonMatch";
          rules = [
            {
              ip = [ "geoip:private" ];
              outboundTag = "block";
            }
            {
              ip = [ "geoip:cn" ];
              outboundTag = "block";
            }
            {
              domain = [ "geosite:category-ads-all" ];
              outboundTag = "block";
            }
          ];
        };
        inbounds = [
          {
            tag = "portal";
            protocol = "vless";
            listen = "[::1]";
            port = config.ports.portal-internal;
            settings = {
              clients = [
                {
                  id = config.sops.placeholder."xray_id_yinfeng";
                  email = "yinfeng@li7g.com";
                  flow = "xtls-rprx-vision";
                  level = 0;
                }
                {
                  id = config.sops.placeholder."xray_id_guest";
                  email = "guest@li7g.com";
                  flow = "xtls-rprx-vision";
                  level = 0;
                }
              ];
              decryption = config.sops.placeholder."xray_vless_decryption";
            };
            streamSettings = {
              network = "xhttp";
              security = "none";
              xhttpSettings = {
                mode = "auto";
                path = "/${config.sops.placeholder."xray_service_name"}";
              };
            };
          }
        ];
        outbounds = [
          {
            tag = "direct";
            protocol = "freedom";
          }
          {
            tag = "block";
            protocol = "blackhole";
          }
        ];
      };
    })

    (lib.mkIf cfg.client.enable {
      sops.templates.portal-xray.content =
        let
          basicConfig = {
            log = {
              loglevel = cfg.logLevel;
            };
            dns = {
              servers = [
                {
                  address = "1.1.1.1";
                  domains = [ "geosite:geolocation-!cn" ];
                }
                {
                  address = "223.5.5.5";
                  domains = [ "geosite:cn" ];
                  expectIPs = [ "geoip:cn" ];
                }
                {
                  address = "114.114.114.114";
                  domains = [ "geosite:cn" ];
                }
                "localhost"
              ];
            };
            routing = {
              domainStrategy = "IPIfNonMatch";
              rules = [
                {
                  "domain" = [ "geosite:category-ads-all" ];
                  "outboundTag" = "block";
                }
                {
                  domain = [ "geosite:cn" ];
                  outboundTag = "direct";
                }
                {
                  domain = [ "geosite:geolocation-!cn" ];
                  outboundTag = "proxy";
                }
                {
                  ip = [ "223.5.5.5" ];
                  outboundTag = "direct";
                }
                {
                  ip = [
                    "geoip:cn"
                    "geoip:private"
                  ];
                  outboundTag = "direct";
                }
              ];
            };
            inbounds = [
              {
                tag = "socks-in";
                protocol = "socks";
                listen = "[::1]";
                port = config.ports.portal-socks;
                settings = {
                  udp = true;
                };
              }
              {
                tag = "http-in";
                protocol = "http";
                listen = "[::1]";
                port = config.ports.portal-http;
              }
            ];
            outbounds = [
              {
                tag = "proxy";
                protocol = "vless";
                settings = {
                  address = "portal.li7g.com";
                  port = 443;
                  id = config.sops.placeholder."xray_id_yinfeng";
                  flow = "xtls-rprx-vision";
                  encryption = config.sops.placeholder."xray_vless_encryption";
                  level = 0;
                };
                streamSettings = {
                  network = "xhttp";
                  security = "tls";
                  tlsSettings = {
                    serverName = "portal.li7g.com";
                    allowInsecure = false;
                    fingerprint = "chrome";
                  };
                  xhttpSettings = {
                    mode = "auto";
                    path = "/${config.sops.placeholder."xray_service_name"}";
                  };
                };
              }
              {
                tag = "direct";
                protocol = "freedom";
              }
              {
                tag = "block";
                protocol = "blackhole";
              }
            ];
          };
        in
        builtins.toJSON (lib.recursiveUpdate basicConfig cfg.client.extraV2rayConfig);
    })
  ];
}
