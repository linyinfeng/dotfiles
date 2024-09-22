{ config, lib, ... }:
{
  options.ports = lib.mkOption {
    type = with lib.types; attrsOf port;
    default = { };
  };

  config = {
    assertions = [
      {
        assertion =
          let
            vals = lib.attrValues config.ports;
            noCollision = l: lib.length (lib.unique l) == lib.length l;
          in
          noCollision vals;
        message = "ports collision";
      }
    ];

    ports = {
      ssh-honeypot = 22;
      dns = 53;
      http = 80;
      bgp = 179;
      https = 443;
      smtp-tls = 465;
      ipsec-ike = 500;
      smtp-starttls = 587;
      dns-over-tls = 853;
      jellyfin-auto-discovery-1 = 1900;
      ssh = 2222;

      pastebin = 3000;
      vaultwarden-http = 3010;
      vaultwarden-websocket = 3011;
      influxdb = 3020;
      loki = 3030;
      grafana = 3040;
      alertmanager = 3050;
      seafile-file-server = 3060;
      hydra = 3070;
      nix-serve = 3080;
      matrix = 3090;
      matrix-manhole = 3091;
      matrix-sliding-sync = 3092;
      mautrix-telegram-appservice = 3100;
      matrix-qq-appservice = 3101;
      minio = 3110;
      minio-console = 3111;
      sigv4-proxy = 3120;
      dot-tar = 3130;
      proxy-http = 3140;
      proxy-socks = 3141;
      proxy-mixed = 3142;
      proxy-tproxy = 3143;
      proxy-dns = 3149;
      clash-controller = 3150;
      transmission-rpc = 3160;
      elasticsearch = 3170;
      elasticsearch-node-to-node = 3171;
      bind-http = 3180;
      oranc = 3190;
      hledger-web = 3200;
      syncthing = 3210;
      syncthing-yinfeng = 3211;
      syncthing-discovery = 3220;
      syncthing-transfer = 3230;
      gortr = 3240;
      gortr-metric = 3241;
      bird-lg-proxy = 3250;
      bird-lg-frontend = 3251;
      keycloak = 3260;
      qrcp = 3270;
      portal-socks = 3280;
      portal-internal = 3281;
      rathole = 3290;
      ntfy = 3300;
      atuin = 3310;
      vlmcsd = 3330;
      jellyfin = 3340;
      jellyfin-https = 3341;
      iperf = 3350;
      typhon = 3360;
      rabbitmq = 3370;
      rabbitmq-management = 3371;
      sicp-staging = 3390;
      sicp-staging-redis = 3391;

      ipsec-nat-traversal = 4500;
      babel = 6696;
      jellyfin-auto-discovery-2 = 7359;
      http-alternative = 8080;
      https-alternative = 8443;
      zerotier = 9993;
      dn42-mesh-min = 19000;
      # interval: no ports here
      dn42-mesh-max = 19999;
      dn42-peer-min = 20000;
      # interval: no ports here
      dn42-peer-max = 23999;
      minecraft-voice = 24454;
      minecraft = 25565;
      minecraft-rcon = 25566;
      minecraft-map = 25567;
      mongodb = 27017; # currently change is not supported in nixpkgs module
      teamspeak-voice = 9987;
      teamspeak-file-transfer = 30033;
      teamspeak-query = 10011;
      syncthing-discovery-yinfeng = 21027; # TODO change to 3221
      syncthing-transfer-yinfeng = 22000; # TODO change to 3231
      tailscale = 41641;
      wireguard = 51820;
    };
  };
}
