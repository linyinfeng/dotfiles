{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.networking.campus-network;
  scripts = pkgs.buildEnv {
    name = "campus-network-scripts";
    paths = [
      campusNetLogin
      campusNetLogout
      autoLogin
    ];
  };
  campusNetLogin = pkgs.writeShellApplication {
    name = "campus-net-login";
    runtimeInputs = with pkgs; [
      curl
    ];
    text = ''
      username=$(cat "${config.sops.secrets."campus-net/username".path}")
      password=$(cat "${config.sops.secrets."campus-net/password".path}")

      curl -X POST https://p.nju.edu.cn/api/portal/v1/login \
        --json @- <<EOF
        {
          "username": "$username",
          "password": "$password"
        }
      EOF
    '';
  };
  campusNetLogout = pkgs.writeShellApplication {
    name = "campus-net-logout";
    runtimeInputs = with pkgs; [
      curl
    ];
    text = ''
      curl -X POST https://p.nju.edu.cn/api/portal/v1/logout --json "{}"
    '';
  };
  autoLogin = pkgs.writeShellApplication {
    name = "campus-net-auto-login";
    runtimeInputs = with pkgs; [
      curl
      campusNetLogin
    ];
    text = ''
      interval="${toString cfg.auto-login.interval}"
      max_time="${toString cfg.auto-login.testMaxTime}"

      function test_and_login {
        echo -n "curl --ipv4 'http://captive.apple.com': "
        if
          curl --ipv4 http://captive.apple.com --silent --show-error --max-time "$max_time" |
            grep Success >/dev/null
        then
          # do nothing
          echo "already logged in"
        else
          echo "no internet, try login"
          campus-net-login
        fi
      }
      while true; do
        test_and_login || true # always continue
        sleep "$interval"
      done
    '';
  };
in
{
  options.networking.campus-network = {
    enable = lib.mkEnableOption "campus-network";
    auto-login = {
      enable = lib.mkEnableOption "campus-net-auto-login";
      interval = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = ''
          Auto login interval in seconds
        '';
      };
      testMaxTime = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = ''
          Max time to test connection
        '';
      };
    };
  };
  config = lib.mkIf cfg.enable {
    passthru.campus-net-scripts = scripts;
    environment.systemPackages = [ scripts ];
    sops.secrets."campus-net/username" = {
      sopsFile = config.sops-file.get "common.yaml";
      restartUnits = [ "campus-net-auto-login.service" ];
    };
    sops.secrets."campus-net/password" = {
      sopsFile = config.sops-file.get "common.yaml";
      restartUnits = [ "campus-net-auto-login.service" ];
    };

    systemd.services."campus-net-auto-login" = {
      inherit (cfg.auto-login) enable;
      serviceConfig = {
        ExecStart = "${scripts}/bin/campus-net-auto-login";
      };
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
