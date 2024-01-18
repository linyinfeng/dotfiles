{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.fw-proxy;

  mixedPort = cfg.ports.mixed;
  tproxyPort = cfg.ports.tproxy;

  enableProxy = pkgs.writeShellApplication {
    name = "enable-proxy";
    text = ''
      ${lib.concatMapStringsSep "\n" (env: ''export ${env.name}="${env.value}"'') (lib.attrsToList cfg.environment)}
    '';
  };
  disableProxy = pkgs.writeShellApplication {
    name = "disable-proxy";
    text = ''
      ${lib.concatMapStringsSep "\n" (name: ''export ${name}=""'') (lib.attrNames cfg.environment)}
    '';
  };
  updateSingBoxUrl = pkgs.writeShellApplication {
    name = "update-sing-box-url";
    runtimeInputs = with pkgs; [
      curl
      jq
      yq
      moreutils
      systemd
      clash2sing-box
    ];
    text = ''
      dir="/etc/sing-box"

      url=""
      downloaded_config_type="sing-box"
      keep_temporary_directory="NO"
      profile_name=""

      positional_args=()
      while [[ $# -gt 0 ]]; do
        case $1 in
        --clash)
          downloaded_config_type="clash"
          shift
          ;;
        --keep-temporary-directory)
          keep_temporary_directory="YES"
          shift
          ;;
        --profile-name)
          profile_name="$2"
          shift
          shift
          ;;
        -* )
          echo "unknown option $1" >&2
          exit 1
          ;;
        *)
          positional_args+=("$1")
          shift
          ;;
        esac
      done
      if [ "''${#positional_args[@]}" = "1" ]; then
        url="''${positional_args[0]}"
      else
        echo "invalid arguments ''${positional_args[*]}" >&2
        exit 1
      fi

      mkdir -p $dir

      echo 'Making temporary directory...'
      tmp_dir=$(mktemp -t --directory update-sing-box-config.XXXXXXXXXX)
      echo "Temporary directory is: $tmp_dir"
      if [ -f "$dir/config.json" ]; then
        echo 'Backup old config.json...'
        cp "$dir/config.json" "$dir/config.json.old"
      fi
      function cleanup {
        if [ "$keep_temporary_directory" != "YES" ]; then
          echo 'Remove temporary directory...'
          rm -rf "$tmp_dir"
        fi
        if [ -f "$dir/config.json.old" ]; then
          echo 'Restore old config.json...'
          cp "$dir/config.json.old" "$dir/config.json"
          rm "$dir/config.json.old"
        fi
      }
      trap cleanup EXIT

      echo 'Downloading original configuration...'
      downloaded_config="$tmp_dir/downloaded-config"
      curl "$url" \
        --fail-with-body \
        --show-error \
        --output "$downloaded_config"
      profile_info_file="$tmp_dir/profile-info"
      jq --null-input \
        --arg u "$url" \
        --arg p "$profile_name" \
        '{"url": $u, "profile_name": $p}' \
        >"$profile_info_file"

      echo 'Preprocessing original configuration...'
      ${cfg.downloadedConfigPreprocessing}

      echo 'Converting downloaded configuration file to raw config.json...'
      raw_config="$tmp_dir/raw-config.json"
      if [ "$downloaded_config_type" = "sing-box" ]; then
        cp "$downloaded_config" "$raw_config"
        elif [ "$downloaded_config_type" = "clash" ]; then
        ctos-${pkgs.stdenv.hostPlatform.system} --source="$downloaded_config" gen >"$raw_config"
      else
        echo "unknown config type: ''${downloaded_config_type}" >&2
        exit 1
      fi

      echo 'Preprocessing raw config.json...'
      ${cfg.configPreprocessing}

      echo 'Build config.json...'
      jq --slurp '.[0] * .[1]' "$raw_config" - <<EOF >"$dir/config.json"
      ${builtins.toJSON cfg.mixinConfig}
      EOF

      external_controller_secrets=$(cat "${cfg.externalController.secretFile}")
      jq "
        .experimental.clash_api.secret = \"''${external_controller_secrets}\" |
        .experimental.clash_api.external_ui = \"${pkgs.nur.repos.linyinfeng.yacd}\"
        " "$dir/config.json" | sponge "$dir/config.json"

      echo 'Restarting sing-box...'
      systemctl restart sing-box
      systemctl status sing-box --no-pager
      if [ -f "$dir/config.json.old" ]; then
        echo 'Remove old config.json...'
        rm "$dir/config.json.old"
      fi
    '';
  };
  updateSingBox = pkgs.writeShellApplication {
    name = "update-sing-box";
    runtimeInputs = [
      updateSingBoxUrl
    ];
    text = ''
      profile="$1"
      shift
      case "$profile" in
      ${lib.concatMapStringsSep "\n" (p: ''
        "${p.name}")
          update-sing-box-url "$(cat "${p.urlFile}")" --profile-name "$profile" "$@"
          ;;
      '') (lib.attrValues cfg.profiles)}
      *)
        update-sing-box-url "$profile" "$@"
        ;;
      esac
    '';
  };
  tproxyUse = pkgs.writeShellApplication {
    name = "fw-tproxy-use";
    runtimeInputs = with pkgs; [
      systemd
    ];
    text = ''
      cgroup_path="${cfg.tproxy.slice}"
      exec systemd-run --pipe --slice="$cgroup_path" "$@"
    '';
  };
  tproxyCgroup = pkgs.writeShellApplication {
    name = "fw-tproxy-cgroup";
    runtimeInputs = with pkgs; [
      nftables
    ];
    text = ''
      nft_table="${cfg.tproxy.nftTable}"

      function usage {
        cat <<EOF
      Usage:
        $0 list
        $0 add    PATH
        $0 delete PATH
      EOF
        exit 0
      }

      if [ $# -lt 1 ]; then usage; fi
      action="$1"
      case "$action" in
      list)
        if [ $# != 1 ]; then usage; fi
        nft list set inet "$nft_table" cgroups
        ;;
      add | delete)
        path="$2"
        if [ $# != 2 ]; then usage; fi
        nft "$action" element inet "$nft_table" cgroups "{ \"$path\" }"
        ;;
      *)
        usage
        ;;
      esac
    '';
  };
  tproxyInterface = pkgs.writeShellApplication {
    name = "fw-tproxy-if";
    runtimeInputs = with pkgs; [
      nftables
    ];
    text = ''
      nft_table="${cfg.tproxy.nftTable}"

      function usage {
        cat <<EOF
      Usage:
        $0 list
        $0 add    INTERFACE
        $0 delete INTERFACE
      EOF
        exit 0
      }

      if [ $# -lt 1 ]; then usage; fi
      action="$1"
      case "$action" in
      list)
        if [ $# != 1 ]; then usage; fi
        nft list set inet "$nft_table" proxied-interfaces
        ;;
      add | delete)
        if [ $# != 2 ]; then usage; fi
        interface="$2"
        nft "$action" element inet "$nft_table" proxied-interfaces "{ $interface }"
        ;;
      *)
        usage
        ;;
      esac
    '';
  };

  scripts = pkgs.symlinkJoin {
    name = "fw-proxy-scripts";
    paths = [
      enableProxy
      disableProxy
      updateSingBoxUrl
      updateSingBox
      tproxyUse
      tproxyCgroup
      tproxyInterface
    ];
  };

  profileOptions = {name, ...}: {
    options = {
      name = lib.mkOption {
        type = with lib.types; str;
        default = name;
      };
      urlFile = lib.mkOption {
        type = with lib.types; path;
      };
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
      profiles = mkOption {
        type = with types; attrsOf (submodule profileOptions);
        default = {};
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
      noProxyPattern = mkOption {
        type = with types; listOf str;
        default = [
          "localhost"
          "127.0.0.0/8"
          "::1"
          "10.0.0.0/8"
          "192.168.0.0/16"
          "172.16.0.0/12"
        ];
      };
      noProxy = mkOption {
        type = types.str;
        default = lib.concatStringsSep "," cfg.noProxyPattern;
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
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
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
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
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
              fib daddr type local accept
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
