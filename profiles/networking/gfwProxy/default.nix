{ config, lib, pkgs, ... }:
let
  cfg = config.networking.gfwProxy;
  clashUser = "clash";
  clashDir = "/var/lib/clash";

  copyScripts = ''
    mkdir -p $out/bin
    cp -R $src/* $out/bin
  '';
  scripts = pkgs.pkgs.stdenv.mkDerivation {
    name = "gfw-proxy-scripts";
    src = ./scripts;
    installPhase = copyScripts;
  };
  secretScripts = pkgs.pkgs.stdenv.mkDerivation {
    name = "gfw-proxy-secret-scripts";
    src = ../../../secrets/networking/gfwProxy/scripts;
    installPhase = copyScripts;
  };
in
with lib;
{
  options.networking.gfwProxy = {
    environment = mkOption {
      type = types.attrsOf types.str;
      description = ''
        Proxy environment to bypass GFW.
      '';
    };

    stringEnvironment = mkOption {
      type = types.listOf types.str;
      description = ''
        Proxy environment in strings.
      '';
    };
  };

  config = {
    networking.gfwProxy.environment =
      let
        proxyUrl = "http://localhost:8899/";
      in
      {
        HTTP_PROXY = proxyUrl;
        HTTPS_PROXY = proxyUrl;
        http_proxy = proxyUrl;
        https_proxy = proxyUrl;
      };
    networking.gfwProxy.stringEnvironment = map
      (key:
        let value = lib.getAttr key cfg.environment;
        in "${key}=${value}"
      )
      (lib.attrNames cfg.environment);

    systemd.services.nix-daemon.environment = cfg.environment;
    systemd.services.docker.environment = cfg.environment;
    systemd.services.flatpak-system-helper.environment = cfg.environment;

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

    environment.systemPackages = [
      scripts
      secretScripts
    ];

    environment.global-persistence.directories = [ clashDir ];

    system.activationScripts.fixClashDirectoryPremission = ''
      chown "${clashUser}" "${clashDir}"
    '';

    virtualisation.oci-containers.containers.yacd = {
      image = "haishanh/yacd";
      ports = [
        "30001:80"
      ];
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY"
      Defaults env_keep += "http_proxy https_proxy ftp_proxy all_proxy no_proxy"
    '';
  };
}
