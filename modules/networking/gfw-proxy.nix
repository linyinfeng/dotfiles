{ config, lib, pkgs, ... }:
let
  cfg = config.networking.gfw-proxy;

  clashUser = "clash";
  clashDir = "/var/lib/clash";

  scripts = pkgs.stdenvNoCC.mkDerivation rec {
    name = "gfw-proxy-scripts";
    buildCommand = ''
      install -Dm644 $enableProxy    $out/bin/enable-proxy
      install -Dm644 $disableProxy   $out/bin/disable-proxy
      install -Dm755 $updateClashUrl $out/bin/update-clash-url
      install -Dm755 $updateClash    $out/bin/update-clash
    '';
    enableProxy = pkgs.substituteAll {
      src = ./gfw-proxy/enable-proxy;
      mixedPort = cfg.port.mixed;
    };
    disableProxy = pkgs.substituteAll {
      src = ./gfw-proxy/disable-proxy;
    };
    updateClashUrl = pkgs.substituteAll {
      src = ./gfw-proxy/update-clash-url.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) coreutils curl systemd;
      yqGo = pkgs.yq-go;
      httpPort = cfg.port.http;
      socksPort = cfg.port.socks5;
      redirPort = cfg.port.redir;
      mixedPort = cfg.port.mixed;
      externalControllerPort = cfg.port.externalController;
      directory = clashDir;
    };
    updateClash = pkgs.substituteAll {
      src = ../../secrets/networking/gfw-proxy/update-clash.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit updateClashUrl;
    };
  };
in
with lib;
{
  options.networking.gfw-proxy = {
    enable = mkOption {
      type = with types; bool;
      default = false;
    };
    port = {
      http = mkOption {
        type = with types; int;
        default = 7890;
      };
      socks5 = mkOption {
        type = with types; int;
        default = 7891;
      };
      redir = mkOption {
        type = with types; int;
        default = 7893;
      };
      mixed = mkOption {
        type = with types; int;
        default = 8899;
      };
      externalController = mkOption {
        type = with types; int;
        default = 7900;
      };
      webui = mkOption {
        type = with types; int;
        default = 7901;
      };
    };
    environment = mkOption {
      type = with types; attrsOf str;
      description = ''
        Proxy environment.
      '';
    };
    stringEnvironment = mkOption {
      type = with types; listOf str;
      description = ''
        Proxy environment in strings.
      '';
    };
  };

  config = mkIf (cfg.enable) {
    networking.gfw-proxy.environment =
      let
        proxyUrl = "http://localhost:${toString cfg.port.mixed}/";
      in
      {
        HTTP_PROXY = proxyUrl;
        HTTPS_PROXY = proxyUrl;
        http_proxy = proxyUrl;
        https_proxy = proxyUrl;
      };
    networking.gfw-proxy.stringEnvironment = map
      (key:
        let value = lib.getAttr key cfg.environment;
        in "${key}=${value}"
      )
      (lib.attrNames cfg.environment);

    users.users.${clashUser} = {
      isSystemUser = true;
    };
    systemd.services.clash-premium = {
      description = "A rule based proxy in GO";
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "exec";
        User = "clash";
        Group = "nogroup";
        Restart = "on-abort";
        ExecStart = ''
          ${pkgs.nur.repos.linyinfeng.clash-premium}/bin/clash-premium -d "${clashDir}"
        '';
      };
      wantedBy = [ "multi-user.target" ];
    };
    environment.global-persistence.directories = [ clashDir ];
    system.activationScripts.fixClashDirectoryPremission = ''
      chown "${clashUser}" "${clashDir}"
    '';
    environment.systemPackages = [
      scripts
    ];
    virtualisation.oci-containers.containers.yacd = {
      image = "haishanh/yacd";
      ports = [
        "${toString cfg.port.webui}:80"
      ];
    };

    programs.proxychains = {
      enable = true;
      chain.type = "strict";
      proxies = {
        clash = {
          enable = true;
          type = "socks5";
          host = "127.0.0.1";
          port = cfg.port.mixed;
        };
      };
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"
      Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
    '';
  };
}
