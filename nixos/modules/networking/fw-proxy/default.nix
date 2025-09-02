{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.fw-proxy;

  mixedPort = cfg.ports.mixed;
  tproxyPort = cfg.ports.tproxy;

  mkProxyScript =
    name: env:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        ${lib.concatMapStringsSep "\n" (env: ''export ${env.name}="${env.value}"'') (lib.attrsToList env)}
      '';
    };
  enableProxy = mkProxyScript "enable-proxy" cfg.environmentCommandLine;
  enableContainerProxy = mkProxyScript "enable-container-proxy" cfg.environmentContainer;
  disableProxy = mkProxyScript "disable-proxy" cfg.environmentDisable;
  updateFwProxyUrl = pkgs.writeShellApplication {
    name = "update-fw-proxy-url";
    runtimeInputs = with pkgs; [
      curl
      jq
      yq-go
      moreutils
      systemd
    ];
    text = ''
      dir="/var/lib/fw-proxy"

      url=""
      downloaded_config_type="clash"
      keep_temporary_directory="NO"
      profile_name=""
      filename="config.yaml"

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
      tmp_dir=$(mktemp -t --directory update-fw-proxy-config.XXXXXXXXXX)
      echo "Temporary directory is: $tmp_dir"
      if [ -f "$dir/$filename" ]; then
        echo "Backup old $filename..."
        cp "$dir/$filename" "$dir/$filename.old"
      fi
      function cleanup {
        if [ "$keep_temporary_directory" != "YES" ]; then
          echo 'Remove temporary directory...'
          rm -rf "$tmp_dir"
        fi
        if [ -f "$dir/$filename.old" ]; then
          echo "Restore old $filename..."
          cp "$dir/$filename.old" "$dir/$filename"
          rm "$dir/$filename.old"
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

      echo "Converting downloaded configuration file to raw $filename..."
      raw_config="$tmp_dir/raw-$filename"
      if [ "$downloaded_config_type" = "clash" ]; then
        cp "$downloaded_config" "$raw_config"
      else
        echo "unknown config type: ''${downloaded_config_type}" >&2
        exit 1
      fi

      echo "Preprocessing raw $filename..."
      ${cfg.configPreprocessing}

      echo "Build $filename..."
      yq eval-all --prettyPrint 'select(fileIndex == 0) * select(fileIndex == 1)' "$raw_config" - <<EOF >"$dir/$filename"
      ${builtins.toJSON cfg.mixinConfig}
      EOF

      echo 'Restarting fw-proxy.service...'
      systemctl restart fw-proxy
      systemctl status fw-proxy --no-pager
      if [ -f "$dir/$filename.old" ]; then
        echo "Remove old $filename..."
        rm "$dir/$filename.old"
      fi
    '';
  };
  updateFwProxy = pkgs.writeShellApplication {
    name = "update-fw-proxy";
    runtimeInputs = [ updateFwProxyUrl ];
    text = ''
      profile="$1"
      shift
      case "$profile" in
      ${lib.concatMapStringsSep "\n" (p: ''
        "${p.name}")
          update-fw-proxy-url "$(cat "${p.urlFile}")" --profile-name "$profile" "$@"
          ;;
      '') (lib.attrValues cfg.profiles)}
      *)
        update-fw-proxy-url "$profile" "$@"
        ;;
      esac
    '';
  };
  tproxyUse = pkgs.writeShellApplication {
    name = "fw-tproxy-use";
    runtimeInputs = with pkgs; [ systemd ];
    text = ''
      exec systemd-run --user \
        --property=NFTSet="${cfg.tproxy.nftSet}" \
        --pipe --pty \
        --same-dir \
        --wait "$@"
    '';
  };
  tproxyCgroup = pkgs.writeShellApplication {
    name = "fw-tproxy-cgroup";
    runtimeInputs = with pkgs; [ nftables ];
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
    runtimeInputs = with pkgs; [ nftables ];
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
      enableContainerProxy
      disableProxy
      updateFwProxyUrl
      updateFwProxy
      tproxyUse
      tproxyCgroup
      tproxyInterface
    ];
  };

  profileOptions =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = with lib.types; str;
          default = name;
        };
        urlFile = lib.mkOption { type = with lib.types; path; };
      };
    };
in
with lib;
{
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
      # table name currently can not contain '-' due to systemd limitation
      # https://github.com/systemd/systemd/issues/31189
      nftTable = mkOption {
        type = with types; str;
        # tproxy is a keyword in nft
        default = "fwtproxy";
      };
      nftSet = mkOption {
        type = with types; str;
        default = "cgroup:inet:${cfg.tproxy.nftTable}:cgroups";
      };
      bypassNftSet = mkOption {
        type = with types; str;
        default = "cgroup:inet:${cfg.tproxy.nftTable}:bypass";
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
    mixinConfig = mkOption { type = with types; attrsOf anything; };
    ports = {
      all = lib.mkOption {
        type = with types; listOf port;
        readOnly = true;
        default = with cfg.ports; [
          http
          socks
          mixed
          tproxy
        ];
      };
      http = mkOption { type = with types; port; };
      socks = mkOption { type = with types; port; };
      mixed = mkOption { type = with types; port; };
      tproxy = mkOption { type = with types; port; };
      controller = mkOption { type = with types; port; };
    };
    profiles = mkOption {
      type = with types; attrsOf (submodule profileOptions);
      default = { };
    };
    externalController = {
      expose = mkOption { type = with types; bool; };
      virtualHost = mkOption {
        type = with types; str;
        default = "localhost";
      };
      location = mkOption {
        type = with types; str;
        default = "/";
      };
      secretFile = mkOption { type = with types; path; };
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
      default =
        let
          proxyUrl = "http://localhost:${toString mixedPort}";
        in
        {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
        };
    };
    environmentCommandLine = mkOption {
      type = with types; attrsOf str;
      description = ''
        Proxy environment for command line.
      '';
      default =
        let
          proxyUrl = "http://localhost:${toString mixedPort}";
          socksProxyUrl = "socks5h://localhost:${toString mixedPort}";
        in
        {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          ALL_PROXY = socksProxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
          all_proxy = socksProxyUrl;
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
        };
    };
    environmentContainer = mkOption {
      type = with types; attrsOf str;
      description = ''
        Proxy environment for containers.
      '';
      default =
        let
          proxyUrl = "http://host.containers.internal:${toString mixedPort}";
        in
        {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
        };
    };
    environmentDisable = mkOption {
      type = with types; attrsOf str;
      description = ''
        Proxy environment for disabling proxy.
      '';
      default =
        let
          proxyUrl = "";
        in
        {
          HTTP_PROXY = proxyUrl;
          HTTPS_PROXY = proxyUrl;
          ALL_PROXY = proxyUrl;
          http_proxy = proxyUrl;
          https_proxy = proxyUrl;
          all_proxy = proxyUrl;
          NO_PROXY = cfg.noProxy;
          no_proxy = cfg.noProxy;
        };
    };
    stringEnvironment = mkOption {
      type = with types; listOf str;
      description = ''
        Proxy environment in strings.
      '';
      default = map (
        key:
        let
          value = lib.getAttr key cfg.environment;
        in
        "${key}=${value}"
      ) (lib.attrNames cfg.environment);
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

  config = mkIf cfg.enable (mkMerge [
    {
      networking.fw-proxy.mixinConfig = {
        port = cfg.ports.http;
        socks-port = cfg.ports.socks;
        tproxy-port = cfg.ports.tproxy;
        mixed-port = cfg.ports.mixed;
        external-controller = "127.0.0.1:${toString cfg.ports.controller}";
        external-ui = "${pkgs.nur.repos.linyinfeng.yacd}";
        allow-lan = lib.mkDefault true;
        global-client-fingerprint = lib.mkDefault "random";
        ipv6 = lib.mkDefault true;
        geo-auto-update = lib.mkDefault true;
        geo-update-interval = lib.mkDefault 8;
        geox-url =
          let
            meta-rules-dat = "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release";
          in
          {
            geoip = "${meta-rules-dat}/geoip.dat";
            geosite = "${meta-rules-dat}/geosite.dat";
            mmdb = "${meta-rules-dat}/country.mmdb";
          };
        unified-delay = lib.mkDefault true;
        tcp-concurrent = lib.mkDefault true;
      };
    }

    {
      systemd.services.fw-proxy = {
        script = ''
          external_controller_secret=$(cat "$CREDENTIALS_DIRECTORY/secret")
          mihomo -d "$STATE_DIRECTORY" -secret "$external_controller_secret"
        '';
        reload = "kill -HUP $MAINPID";
        path = with pkgs; [ mihomo ];
        environment = {
          SKIP_SAFE_PATH_CHECK = "1";
        };
        serviceConfig =
          let
            capabilities = [
              "CAP_NET_ADMIN"
              "CAP_NET_RAW"
              "CAP_NET_BIND_SERVICE"
              "CAP_SYS_TIME"
              "CAP_SYS_PTRACE"
              "CAP_DAC_READ_SEARCH"
            ];
          in
          {
            Type = "simple";
            LimitNPROC = 500;
            LimitNOFILE = 1000000;
            CapabilityBoundingSet = capabilities;
            AmbientCapabilities = capabilities;
            Restart = "on-failure";
            DynamicUser = true;
            StateDirectory = "fw-proxy";
            NFTSet = [ cfg.tproxy.bypassNftSet ];
            LoadCredential = [ "secret:${cfg.externalController.secretFile}" ];
          };
        after = [ "nftables.service" ];
        requires = [ "nftables.service" ];
        wantedBy = [ "multi-user.target" ];
      };

      environment.systemPackages = [ scripts ];
      security.sudo-rs.extraConfig = ''
        Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"
        Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
      '';
    }

    (mkIf cfg.externalController.expose {
      services.nginx.enable = true;
      services.nginx.virtualHosts.${cfg.externalController.virtualHost} = {
        locations = {
          "${cfg.externalController.location}" = {
            proxyPass = "http://${cfg.mixinConfig.external-controller}/";
            proxyWebsockets = true;
          };
        };
      };
    })

    (mkIf cfg.tproxy.enable {
      networking.routerBasics.enable = true;
      systemd.network.config.routeTables = {
        fw-tproxy = cfg.tproxy.routingTable;
      };
      systemd.network.networks."80-fw-tproxy" = {
        matchConfig = {
          Name = "lo";
        };
        routes = [
          {
            Destination = "0.0.0.0/0";
            Type = "local";
            Table = cfg.tproxy.routingTable;
          }
          {
            Destination = "::/0";
            Type = "local";
            Table = cfg.tproxy.routingTable;
          }
        ];
        routingPolicyRules = [
          {
            Family = "both";
            FirewallMark = cfg.tproxy.fwmark;
            Priority = config.routingPolicyPriorities.fw-proxy;
            Table = cfg.tproxy.routingTable;
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
          }

          set bypass {
            type cgroupsv2
            counter
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

            socket cgroupv2 level 2 @bypass counter return comment "bypass packets of proxy service"

            jump filter

            ${lib.concatMapStringsSep "\n" (
              level:
              "meta l4proto { tcp, udp } socket cgroupv2 level ${toString level} @cgroups meta mark set ${toString cfg.tproxy.fwmark}"
            ) (lib.range 1 cfg.tproxy.maxCgroupLevel)}
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
        # Error: Could not process rule: Operation not supported
        sed 's/^.*socket cgroupv2.*$//g' -i ruleset.conf
      '';
      networking.firewall.extraInputRules = ''
        meta mark ${toString cfg.tproxy.fwmark} counter accept
      '';

      passthru.fw-proxy-tproxy-scripts = scripts;
    })

    (mkIf cfg.auto-update.enable {
      systemd.services.fw-proxy-auto-update = {
        script = ''
          "${scripts}/bin/update-fw-proxy" "${cfg.auto-update.service}"
        '';
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = 30;
        };
        after = [
          "network-online.target"
          "fw-proxy.service"
        ];
        requires = [ "network-online.target" ];
      };
      systemd.timers.fw-proxy-auto-update = {
        timerConfig = {
          OnCalendar = "03:30";
        };
        wantedBy = [ "timers.target" ];
      };
    })

    (mkIf config.virtualisation.podman.enable (
      let
        podmanInterface = config.virtualisation.podman.defaultNetwork.settings.network_interface;
      in
      {
        networking.firewall.interfaces.${podmanInterface}.allowedTCPPorts = cfg.ports.all;
      }
    ))

    (mkIf config.virtualisation.libvirtd.enable (
      let
        libvirtdInterfaces = config.virtualisation.libvirtd.allowedBridges;
        mkIfCfg = name: { ${name}.allowedTCPPorts = cfg.ports.all; };
        ifCfgs = lib.mkMerge (lib.lists.map mkIfCfg libvirtdInterfaces);
      in
      {
        networking.firewall.interfaces = ifCfgs;
      }
    ))
  ]);
}
