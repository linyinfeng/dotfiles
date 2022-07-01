{ config, pkgs, ... }:

let
  port = 51820;
  iptables = "${pkgs.iptables}/bin/iptables";
  subnet = "192.168.233";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "${subnet}.1/24" ];
      listenPort = port;
      privateKeyFile = config.sops.secrets."wireguard/wg0-private-key".path;
      peers = [
        {
          # for matrixlt
          publicKey = "qPZDU8lzdSZeCZqGdS5g0c0YtTRFqxkOzbsdCfmfGxA=";
          allowedIPs = [ "${subnet}.2/32" ];
          persistentKeepalive = 9;
        }
        {
          # for ipid
          publicKey = "rlvof8zMHk5kJu5fW1B0+T6vJqLpUkCMDScKXskL2BE=";
          allowedIPs = [ "${subnet}.3/32" ];
          persistentKeepalive = 9;
        }
        {
          # for yinfeng
          publicKey = "IhRPfSRHEZMzetvKi2nk8vODQAbwSyKcPEw8AjTghyo=";
          allowedIPs = [ "${subnet}.4/32" ];
          persistentKeepalive = 9;
        }
      ];

      preUp = ''
        ${iptables} -t nat -I POSTROUTING -s "${subnet}.0/24" -j MASQUERADE
      '';
      postDown = ''
        ${iptables} -t nat -D POSTROUTING -s "${subnet}.0/24" -j MASQUERADE
      '';
    };
  };

  sops.secrets."wireguard/wg0-private-key".sopsFile = config.sops.secretsDir + /g150ts.yaml;

  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];
}
