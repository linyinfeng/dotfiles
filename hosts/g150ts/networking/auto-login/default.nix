{ config, pkgs, ... }:

let
  service = "auto-login";
  intervalSec = 30;
  curl = "${pkgs.curl}/bin/curl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  systemd.services.${service} = {
    script = ''
      set +e
      function test_and_login {
        echo -n "curl --ipv4 'http://captive.apple.com': "
        "${curl}" --ipv4 http://captive.apple.com --silent --show-error | grep Success > /dev/null
        if [ $? -eq 0 ]; then
          # do nothing
          echo "already logged in"
        else
          echo "no internet"
          url=$(cat ${config.sops.secrets."net-login/url".path})
          data=$(cat ${config.sops.secrets."net-login/data".path})
          "${curl}" -X POST "$url" --data "$data"

          # restart shadowsocks
          "${systemctl}" restart shadowsocks-rust.service
        fi
      }
      while true; do
        test_and_login
        sleep ${toString intervalSec}s;
      done
    '';
  };
  systemd.services.NetworkManager.requires = [ "${service}.service" ];
  sops.secrets."net-login/url".sopsFile = config.sops.secretsDir + /hosts/g150ts.yaml;
  sops.secrets."net-login/data".sopsFile = config.sops.secretsDir + /hosts/g150ts.yaml;
}
