{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.fw-proxy;

  mixedPort = cfg.ports.mixed;
  tproxyPort = cfg.ports.tproxy;

  scripts = pkgs.stdenvNoCC.mkDerivation rec {
    name = "fw-proxy-scripts";
    buildCommand = ''
      install -Dm644 $enableProxy      $out/bin/enable-proxy
      install -Dm644 $disableProxy     $out/bin/disable-proxy
      install -Dm755 $updateSingBoxUrl $out/bin/update-sing-box-url
      install -Dm755 $updateSingBox    $out/bin/update-sing-box
      install -Dm755 $tproxyUse        $out/bin/fw-tproxy-use
      install -Dm755 $tproxyCgroup     $out/bin/fw-tproxy-cgroup
      install -Dm755 $tproxyInterface  $out/bin/fw-tproxy-if
    '';
    enableProxy = pkgs.substituteAll {
      src = ./enable-proxy;
      inherit mixedPort;
    };
    disableProxy = pkgs.substituteAll {
      src = ./disable-proxy;
    };
    updateSingBoxUrl = pkgs.substituteAll {
      src = ./update-sing-box-url.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) coreutils curl systemd jq;
      yq = pkgs.yq-go;
      moreutils = pkgs.moreutils;
      preprocessingDownloaded = cfg.downloadedConfigPreprocessing;
      preprocessing = cfg.configPreprocessing;
      mixinConfig = builtins.toJSON cfg.mixinConfig;
      directory = "/etc/sing-box";
      externalControllerSecretFile = cfg.externalController.secretFile;
      webui = pkgs.nur.repos.linyinfeng.yacd;
      clash2SingBox = "${pkgs.clash2sing-box}/bin/ctos-${pkgs.stdenv.hostPlatform.system}";
    };
    updateSingBox = pkgs.substituteAll {
      src = ./update-sing-box.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit updateSingBoxUrl;
      mainUrl = config.sops.secrets."sing-box/main".path;
      alternativeUrl = config.sops.secrets."sing-box/alternative".path;
    };
    tproxyUse = pkgs.substituteAll {
      src = ./tproxy-use.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      cgroupPath = cfg.tproxy.slice;
    };
    tproxyCgroup = pkgs.substituteAll {
      src = ./tproxy-cgroup.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (cfg.tproxy) nftTable;
    };
    tproxyInterface = pkgs.substituteAll {
      src = ./tproxy-interface.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (cfg.tproxy) nftTable;
    };
  };
in
  with lib; {
    options.networking.fw-proxy = {
      enable = mkOption {
        type = with types; bool;
        default = false;
      };
      scripts = mkOption {
        type = with types; package;
        default = scripts;
        readOnly = true;
      };
      tproxy = {
        enable = mkOption {
          type = with types; bool;
          default = false;
        };
        routingTable = mkOption {
          type = with types; int;
          default = 854;
        };
        fwmark = mkOption {
          type = with types; int;
          default = 854;
        };
        rulePriority = mkOption {
          type = with types; int;
          default = 26000;
        };
        nftTable = mkOption {
          type = with types; str;
          # tproxy is a keyword in nft
          default = "fw-tproxy";
        };
        slice = mkOption {
          type = with types; str;
          default = "tproxy";
        };
        bypassSlice = mkOption {
          type = with types; str;
          default = "bypasstproxy";
        };
        maxCgroupLevel = mkOption {
          type = with types; int;
          default = 6;
        };
        extraFilterRules = mkOption {
          type = with types; lines;
          default = "";
        };
      };
      configPreprocessing = mkOption {
        type = with types; lines;
        default = "";
      };
      downloadedConfigPreprocessing = mkOption {
        type = with types; lines;
        default = "";
      };
      mixinConfig = mkOption {
        type = with types; attrs;
      };
      ports = {
        mixed = mkOption {
          type = with types; port;
        };
        tproxy = mkOption {
          type = with types; port;
        };
        controller = mkOption {
          type = with types; port;
        };
      };
      externalController = {
        expose = mkOption {
          type = with types; bool;
        };
        virtualHost = mkOption {
          type = with types; str;
          default = "localhost";
        };
        location = mkOption {
          type = with types; str;
          default = "/";
        };
        secretFile = mkOption {
          type = with types; path;
        };
      };
      environment = mkOption {
        type = with types; attrsOf str;
        description = ''
          Proxy environment.
        '';
        default = let
          proxyUrl = "http://localhost:${toString mixedPort}";
        in {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
        };
      };
      environmentContainter = mkOption {
        type = with types; attrsOf str;
        description = ''
          Proxy environment for containers.
        '';
        default = let
          proxyUrl = "http://host.containers.internal:${toString mixedPort}";
        in {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
        };
      };
      stringEnvironment = mkOption {
        type = with types; listOf str;
        description = ''
          Proxy environment in strings.
        '';
        default =
          map
          (
            key: let
              value = lib.getAttr key cfg.environment;
            in "${key}=${value}"
          )
          (lib.attrNames cfg.environment);
      };
      auto-update = {
        enable = mkEnableOption "fw-proxy subscription auto-update";
        service = mkOption {
          type = with types; str;
          description = ''
            Service used in auto update.
          '';
        };
      };
    };

    config = mkIf (cfg.enable) (mkMerge [
      {
        networking.fw-proxy.mixinConfig = let
          commonOptions = {
            listen = "::";
            tcp_fast_open = true;
            udp_fragment = true;
            sniff = true;
          };
        in {
          inbounds = [
            (commonOptions
              // {
                type = "mixed";
                tag = "mixed-in";
                listen_port = cfg.ports.mixed;
              })
            (commonOptions
              // {
                type = "tproxy";
                tag = "tproxy-in";
                listen_port = cfg.ports.tproxy;
              })
          ];
          experimental.clash_api.external_controller = "127.0.0.1:${toString cfg.ports.controller}";
        };
        environment.global-persistence.directories = [
          "/etc/sing-box"
        ];
      }

      {
        systemd.packages = with pkgs; [sing-box];
        systemd.services.sing-box = {
          serviceConfig = {
            DynamicUser = true;

            ExecStartPre = [
              "+${pkgs.coreutils}/bin/chown sing-box:sing-box $CONFIGURATION_DIRECTORY"
              "+${pkgs.coreutils}/bin/chmod 0700              $CONFIGURATION_DIRECTORY"
            ];
            ConfigurationDirectory = "sing-box";
            ConfigurationDirectoryMode = "700";

            StateDirectory = "sing-box";

            # TODO wait for https://github.com/systemd/systemd/pull/29039
            Slice = lib.mkIf (cfg.tproxy.enable) "${cfg.tproxy.bypassSlice}.slice";
          };
          wantedBy = ["multi-user.target"];
        };

        sops.secrets."sing-box/main" = {
          sopsFile = config.sops-file.get "common.yaml";
          restartUnits = ["sing-box-auto-update.service"];
        };
        sops.secrets."sing-box/alternative" = {
          sopsFile = config.sops-file.get "common.yaml";
          restartUnits = ["sing-box-auto-update.service"];
        };

        environment.systemPackages = [
          scripts
        ];
        security.sudo.extraConfig = ''
          Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"
          Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
        '';
      }

      (mkIf (cfg.externalController.expose) {
        services.nginx.enable = true;
        services.nginx.virtualHosts.${cfg.externalController.virtualHost} = {
          locations = {
            "${cfg.externalController.location}" = {
              proxyPass = "http://${cfg.mixinConfig.experimental.clash_api.external_controller}/";
              proxyWebsockets = true;
            };
          };
        };
      })

      (mkIf (cfg.tproxy.enable) {
        netwokring.routerBasics.enable = true;
        systemd.network.config.routeTables = {
          fw-tproxy = cfg.tproxy.routingTable;
        };
        systemd.network.networks."80-fw-tproxy" = {
          matchConfig = {
            Name = "lo";
          };
          routes = [
            {
              routeConfig = {
                Destination = "0.0.0.0/0";
                Type = "local";
                Table = cfg.tproxy.routingTable;
              };
            }
            {
              routeConfig = {
                Destination = "::/0";
                Type = "local";
                Table = cfg.tproxy.routingTable;
              };
            }
          ];
          routingPolicyRules = [
            {
              routingPolicyRuleConfig = {
                Family = "both";
                FirewallMark = cfg.tproxy.fwmark;
                Priority = config.routingPolicyPriorities.fw-proxy;
                Table = cfg.tproxy.routingTable;
              };
            }
          ];
        };
        networking.nftables.tables."${cfg.tproxy.nftTable}" = {
          family = "inet";
          content = ''
            set reserved-ip {
              typeof ip daddr
              flags interval
              elements = {
                10.0.0.0/8,        # private
                100.64.0.0/10,     # private
                127.0.0.0/8,       # loopback
                169.254.0.0/16,    # link-local
                172.16.0.0/12,     # private
                192.0.0.0/24,      # private
                192.168.0.0/16,    # private
                198.18.0.0/15,     # private
                224.0.0.0/4,       # multicast
                255.255.255.255/32 # limited broadcast
              }
            }

            set reserved-ip6 {
              typeof ip6 daddr
              flags interval
              elements = {
                ::1/128,  # loopback
                fc00::/7, # private
                fe80::/10 # link-local
              }
            }

            set proxied-interfaces {
              typeof iif
              counter
            }

            set cgroups {
              type cgroupsv2
              counter
              elements = { "${cfg.tproxy.slice}.slice" }
            }

            set cgroups-bypass {
              type cgroupsv2
              counter
              elements = { "${cfg.tproxy.bypassSlice}.slice" }
            }

            chain prerouting {
              type filter hook prerouting priority mangle; policy accept;

              mark ${toString cfg.tproxy.fwmark} \
                meta l4proto {tcp, udp} \
                tproxy to :${toString tproxyPort} \
                counter \
                accept \
                comment "tproxy and accept marked packets (marked by the output chain)"

              jump filter

              meta l4proto {tcp, udp} \
                iif @proxied-interfaces \
                tproxy to :${toString tproxyPort} \
                mark set ${toString cfg.tproxy.fwmark} \
                counter
            }

            chain output {
              type route hook output priority mangle; policy accept;

              comment "marked packets will be routed to lo"

              socket cgroupv2 level 1 @cgroups-bypass counter return comment "bypass packets of proxy service"

              jump filter

              ${lib.concatMapStringsSep "\n" (level: "meta l4proto { tcp, udp } socket cgroupv2 level ${toString level} @cgroups meta mark set ${toString cfg.tproxy.fwmark}")
              (lib.range 1 cfg.tproxy.maxCgroupLevel)}
            }

            chain filter {
              # TODO enchilada's kernel does not support fib
              # fib daddr type local accept
              ip  daddr @reserved-ip  accept
              ip6 daddr @reserved-ip6 accept

              ${cfg.tproxy.extraFilterRules}
            }
          '';
        };
        networking.nftables.preCheckRuleset = ''
          sed 's/^.*socket cgroupv2.*$//g' -i ruleset.conf
          sed 's/elements = { ".*\.slice" }//g' -i ruleset.conf
        '';
        networking.firewall.extraInputRules = ''
          meta mark ${toString cfg.tproxy.fwmark} counter accept
        '';

        systemd.slices = {
          ${cfg.tproxy.slice} = {
            requiredBy = ["nftables.service"];
            before = ["nftables.service"];
          };
          ${cfg.tproxy.bypassSlice} = {
            requiredBy = ["nftables.service"];
            before = ["nftables.service"];
          };
        };

        passthru.fw-proxy-tproxy-scripts = scripts;
      })

      (mkIf cfg.auto-update.enable {
        systemd.services.sing-box-auto-update = {
          script = ''
            "${scripts}/bin/update-sing-box" "${cfg.auto-update.service}"
          '';
          serviceConfig = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = 30;
          };
          after = ["network-online.target" "sing-box.service"];
        };
        systemd.timers.sing-box-auto-update = {
          timerConfig = {
            OnCalendar = "03:30";
          };
          wantedBy = ["timers.target"];
        };
      })

      (mkIf (config.virtualisation.podman.enable)
        (let
          podmanInterface = config.virtualisation.podman.defaultNetwork.settings.network_interface;
        in {
          networking.firewall.interfaces.${podmanInterface}.allowedTCPPorts = lib.lists.map (i: i.listen_port) cfg.mixinConfig.inbounds;
        }))

      (mkIf (config.virtualisation.libvirtd.enable)
        (let
          libvirtdInterfaces = config.virtualisation.libvirtd.allowedBridges;
          mkIfCfg = name: {
            ${name}.allowedTCPPorts = lib.lists.map (i: i.listen_port) cfg.mixinConfig.inbounds;
          };
          ifCfgs = lib.mkMerge (lib.lists.map mkIfCfg libvirtdInterfaces);
        in {
          networking.firewall.interfaces = ifCfgs;
        }))
    ]);
  }
