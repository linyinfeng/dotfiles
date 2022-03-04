{ pkgs, config, ... }:

let
  port = 8388;
in
{
  systemd.services.shadowsocks-rust = {
    description = "shadowsocks-rust Daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      exec "${pkgs.shadowsocks-rust}/bin/ssserver" \
        -v \
        --server-addr "[::]:${toString port}" \
        --encrypt-method aes-256-gcm \
        --password $(cat "${config.sops.secrets."ss/password".path}")
    '';
  };

  sops.secrets."ss/password".sopsFile = config.sops.secretsDir + /g150t-s.yaml;

  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];
}
