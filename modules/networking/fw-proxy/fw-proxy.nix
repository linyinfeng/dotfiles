{ config, lib, pkgs, ... }:
let
  cfg = config.networking.fw-proxy;

  tunDev = "utun"; # fixed

  scripts = pkgs.stdenvNoCC.mkDerivation rec {
    name = "fw-proxy-scripts";
    buildCommand = ''
      install -Dm644 $enableProxy    $out/bin/enable-proxy
      install -Dm644 $disableProxy   $out/bin/disable-proxy
      install -Dm755 $updateClashUrl $out/bin/update-clash-url
      install -Dm755 $updateClash    $out/bin/update-clash
      install -Dm755 $tunSetup       $out/bin/clash-tun-setup
      install -Dm755 $tunClean       $out/bin/clash-tun-clean
      install -Dm755 $useTunProxy    $out/bin/use-tun-proxy
      install -Dm755 $useTunProxyPid $out/bin/use-tun-proxy-pid
    '';
    enableProxy = pkgs.substituteAll {
      src = ./enable-proxy;
      mixedPort = cfg.mixinConfig.mixed-port;
    };
    disableProxy = pkgs.substituteAll {
      src = ./disable-proxy;
    };
    updateClashUrl = pkgs.substituteAll {
      src = ./update-clash-url.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) coreutils curl systemd;
      yqGo = pkgs.yq-go;
      mixinConfig = builtins.toJSON cfg.mixinConfig;
      directory = "/var/lib/clash-premium";
    };
    updateClash = pkgs.substituteAll {
      src = ./update-clash.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit updateClashUrl;
      mainUrl = config.sops.secrets."clash/main".path;
      alternativeUrl = config.sops.secrets."clash/alternative".path;
    };
    tunSetup = pkgs.substituteAll {
      src = ./tun-setup.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) iproute2 iptables;
      inherit (cfg.tun) routeTable fwmark;
      inherit (cfg.tun.cgroup.netCls) classId;
      inherit tunDev;
    };
    tunClean = pkgs.substituteAll {
      src = ./tun-clean.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) iproute2 iptables;
      inherit (cfg.tun) routeTable fwmark;
      inherit (cfg.tun.cgroup.netCls) classId;
    };
    useTunProxy = pkgs.writeScript "use-tun-proxy" ''
      #!${pkgs.stdenvNoCC.shell}
      ${useTunProxyPid} $$ 2>&1 > /dev/null
      exec "$@"
    '';
    useTunProxyPid =
      let
        cgroupPath = "/sys/fs/cgroup/net_cls/${cfg.tun.cgroup.netCls.name}";
      in
      pkgs.writeScript "use-tun-proxy-pid" ''
        #!${pkgs.stdenvNoCC.shell}
        if [ "$#" != "1" ]; then exit 1; fi

        if [ ! -d "${cgroupPath}" ];then
          echo "cgroup not setup" >&2
          exit 1
        fi

        echo $1 > "${cgroupPath}/tasks"
      '';
  };
in
with lib;
{
  options.networking.fw-proxy = {
    enable = mkOption {
      type = with types; bool;
      default = false;
    };
    tun = {
      enable = mkOption {
        type = with types; bool;
        default = false;
      };
      routeTable = mkOption {
        type = with types; str;
        default = "0x356";
      };
      fwmark = mkOption {
        type = with types; str;
        default = "0x356";
      };
      cgroup.netCls = {
        name = mkOption {
          type = with types; str;
          default = "fw_proxy";
        };
        classId = mkOption {
          type = with types; str;
          default = "0x00010356";
        };
      };
    };
    mixinConfig = mkOption {
      type = with types; attrs;
    };
    webui = {
      enable = mkOption {
        type = with types; bool;
        default = true;
      };
      port = mkOption {
        type = with types; int;
        default = 7901;
      };
    };
    environment = mkOption {
      type = with types; attrsOf str;
      description = ''
        Proxy environment.
      '';
      default =
        let
          proxyUrl = "http://localhost:${toString cfg.mixinConfig.mixed-port}";
        in
        {
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
      default = map
        (key:
          let value = lib.getAttr key cfg.environment;
          in "${key}=${value}"
        )
        (lib.attrNames cfg.environment);
    };
    auto-update = {
      enable = mkEnableOption "clash auto-update";
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
      systemd.services.clash-premium = {
        description = "A rule based proxy in GO";
        script = ''
          "${pkgs.nur.repos.linyinfeng.clash-premium}/bin/clash-premium" -d "$STATE_DIRECTORY"
        '';
        serviceConfig = {
          Type = "exec";
          DynamicUser = true;
          StateDirectory = "clash-premium";
          AmbientCapabilities = [
            "CAP_NET_BIND_SERVICE"
            "CAP_NET_ADMIN"
          ];
        };
        wantedBy = [ "multi-user.target" ];
      };

      sops.secrets."clash/main" = {
        sopsFile = config.sops.secretsDir + /common.yaml;
        restartUnits = [ "clash-auto-update.service" ];
      };
      sops.secrets."clash/alternative" = {
        sopsFile = config.sops.secretsDir + /common.yaml;
        restartUnits = [ "clash-auto-update.service" ];
      };

      environment.systemPackages = [
        scripts
        pkgs.proxychains-ng # add proxychains-ng
      ];
      programs.proxychains = {
        enable = true;
        chain.type = "strict";
        proxies = {
          clash = {
            enable = true;
            type = "socks5";
            host = "127.0.0.1";
            port = cfg.mixinConfig.mixed-port;
          };
        };
      };
      security.sudo.extraConfig = ''
        Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"
        Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
      '';
    }

    (mkIf (cfg.webui.enable) {
      services.nginx.enable = true;
      services.nginx.virtualHosts.localhost = {
        locations = {
          "/yacd/" = {
            alias = "${pkgs.nur.repos.linyinfeng.yacd}/";
            index = "index.html";
          };
        };
      };
    })

    (mkIf (cfg.tun.enable) {
      systemd.services.fw-proxy-cgroup =
        let
          inherit (cfg.tun.cgroup.netCls) name classId;
          path = "/sys/fs/cgroup/net_cls/${name}";
        in
        {
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script =
            ''
              if [ -d "${path}" ];then
                  exit 0
              fi

              if [ ! -d "/sys/fs/cgroup/net_cls" ]; then
                  mkdir -p /sys/fs/cgroup/net_cls
                  "${config.security.wrapperDir}/mount" -onet_cls -t cgroup net_cls /sys/fs/cgroup/net_cls
              fi

              mkdir -p "${path}"
              echo "${classId}" > "${path}/net_cls.classid"
              chmod 666 "${path}/tasks"
            '';
          wantedBy = [ "multi-user.target" ];
        };
      systemd.services.clash-premium = {
        requires = [ "fw-proxy-cgroup.service" ];
        after = [ "fw-proxy-cgroup.service" ];
      };
      networking.fw-proxy.mixinConfig = {
        tun = {
          enable = true;
          stack = "gvisor";
        };
      };
      # Manual enable and disable use clash-tun-setup/clean
      # services.udev.extraRules = ''
      #   SUBSYSTEM=="net",ENV{INTERFACE}=="${tunDev}",ACTION=="add",RUN+="${scripts}/bin/clash-tun-setup"
      #   SUBSYSTEM=="net",ENV{INTERFACE}=="${tunDev}",ACTION=="remove",RUN+="${scripts}/bin/clash-tun-clean"
      # '';

      networking.networkmanager.unmanaged = [ tunDev ];
    })
    (mkIf cfg.auto-update.enable {
      systemd.services.clash-auto-update = {
        script = ''
          "${scripts}/bin/update-clash" "${cfg.auto-update.service}"
        '';
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = 30;
        };
        after = [ "network-online.target" "clash-premium.service" ];
      };
      systemd.timers.clash-auto-update = {
        timerConfig = {
          OnCalendar = "03:30";
        };
        wantedBy = [ "timers.target" ];
      };
    })
  ]);
}
