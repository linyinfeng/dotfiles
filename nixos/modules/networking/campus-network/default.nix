{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.campus-network;
  secretConfig = file: {
    inherit file;
    mode = "440";
    group = config.users.groups.wheel.name;
  };
  scripts = pkgs.stdenvNoCC.mkDerivation rec {
    name = "campus-network-scripts";
    buildCommand = ''
      install -Dm755 $campusNetLogin  $out/bin/campus-net-login
      install -Dm755 $campusNetLogout $out/bin/campus-net-logout
      install -Dm755 $autoLogin       $out/bin/campus-net-auto-login
    '';
    campusNetLogin = pkgs.substituteAll {
      src = ./scripts/login.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) curl;
      usernameFile = config.sops.secrets."campus-net/username".path;
      passwordFile = config.sops.secrets."campus-net/password".path;
    };
    campusNetLogout = pkgs.substituteAll {
      src = ./scripts/logout.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) curl;
    };
    autoLogin = pkgs.substituteAll {
      src = ./scripts/auto-login.sh;
      isExecutable = true;
      inherit (pkgs.stdenvNoCC) shell;
      inherit (pkgs) curl;
      inherit campusNetLogin;
      intervalSec = cfg.auto-login.interval;
      maxTimeSec = cfg.auto-login.testMaxTime;
    };
  };
in {
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
    environment.systemPackages = [
      scripts
    ];
    sops.secrets."campus-net/username" = {
      sopsFile = config.sops-file.get "common.yaml";
      restartUnits = ["campus-net-auto-login.service"];
    };
    sops.secrets."campus-net/password" = {
      sopsFile = config.sops-file.get "common.yaml";
      restartUnits = ["campus-net-auto-login.service"];
    };
    nix.settings.substituters = lib.mkOrder 500 ["https://mirrors.nju.edu.cn/nix-channels/store"];

    systemd.services."campus-net-auto-login" = {
      enable = cfg.auto-login.enable;
      serviceConfig = {
        ExecStart = "${scripts}/bin/campus-net-auto-login";
      };
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
    };
  };
}
