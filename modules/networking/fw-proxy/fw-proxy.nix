{ config, lib, pkgs, ... }:
let
  cfg = config.networking.fw-proxy;

  clashUser = "clash";
  clashDir = "/var/lib/clash";
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
      directory = clashDir;
    };
    updateClash = pkgs.substituteAll {
      src = ./update-clash.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit updateClashUrl;
      dlerUrl = config.age.secrets.clash-dler.path;
      cnixUrl = config.age.secrets.clash-cnix.path;
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
  };

  config = mkIf (cfg.enable) (mkMerge [
    {
      users.users.${clashUser} = {
        isSystemUser = true;
        group = config.users.groups.nogroup.name;
      };
      security.wrappers.clash-premium = {
        source = "${pkgs.nur.repos.linyinfeng.clash-premium}/bin/clash-premium";
        owner = clashUser;
        group = config.users.groups.nogroup.name;
        capabilities = "cap_net_bind_service,cap_net_admin=+ep";
      };
      # TODO: network is not available in vm-test
      systemd.services.clash-premium = lib.mkIf (!config.system.is-vm-test) {
        description = "A rule based proxy in GO";
        serviceConfig = {
          Type = "exec";
          Restart = "on-abort";
          User = clashUser;
          Group = config.users.groups.nogroup.name;
          ExecStart = ''
            "${config.security.wrapperDir}/clash-premium" -d "${clashDir}"
          '';
        };
        wantedBy = [ "multi-user.target" ];
      };
      environment.global-persistence.directories = [ clashDir ];
      system.activationScripts.fixClashDirectoryPremission = ''
        mkdir -p "${clashDir}"
        chown "${clashUser}" "${clashDir}"
      '';
      environment.systemPackages = [
        scripts
      ];
      age.secrets = {
        clash-dler.file = config.age.secrets-directory + /clash-dler.age;
        clash-cnix.file = config.age.secrets-directory + /clash-cnix.age;
      };

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
      virtualisation.oci-containers.containers.yacd = {
        image = "docker.io/haishanh/yacd:latest";
        ports = [
          "${toString cfg.webui.port}:80"
        ];
        extraOptions = [
          "--label"
          "io.containers.autoupdate=registry"
        ];
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
          restartTriggers = [ name classId ];
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
    })
  ]);
}
