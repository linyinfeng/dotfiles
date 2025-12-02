{
  config,
  pkgs,
  lib,
  ...
}:
let
  port = config.ports.ssh-honeypot;
  cowrieSrc = pkgs.stdenv.mkDerivation {
    inherit (pkgs.linyinfeng.sources.cowrie) pname version src;
    patches = [ ./cowrie-telegram-output-requests.patch ];
    installPhase = ''
      cp -r . $out
    '';
  };
in
{
  passthru = {
    inherit cowrieSrc;
  };
  systemd.services.cowrie = {
    # setting up environment as
    # https://github.com/cowrie/cowrie/blob/master/docker/Dockerfile
    script = ''
      rsync --verbose --recursive --delete "${cowrieSrc}/" cowrie-src/
      chmod -R u+w cowrie-src
      mkdir -p cowrie-working
      rsync --verbose --recursive "${cowrieSrc}/var/" cowrie-working/var/
      chmod -R u+w cowrie-working

      rm -f cowrie-venv/bin/python*
      python -m venv cowrie-venv
      # shellcheck source=/dev/null
      source cowrie-venv/bin/activate
      python -m ensurepip --upgrade
      python -m pip install --no-cache-dir --upgrade pip wheel setuptools
      python -m pip install --no-cache-dir --upgrade cffi
      python -m pip install --no-cache-dir --upgrade --requirement cowrie-src/requirements.txt
      python -m pip install --no-cache-dir --upgrade --requirement cowrie-src/requirements-output.txt

      export PYTHONPATH="$PWD/cowrie-src/src"
      python -m compileall cowrie-src cowrie-venv
      cd cowrie-working
      twistd --umask=0022 --nodaemon --pidfile= --logfile=- cowrie
    '';
    path = with pkgs; [
      python311
      gcc
      rsync
    ];
    serviceConfig = {
      User = "cowrie";
      Group = "cowrie";
      StateDirectory = "cowrie";
      WorkingDirectory = "/var/lib/cowrie";
      EnvironmentFile = [ config.sops.templates."cowrie-extra-env".path ];
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
    environment = {
      COWRIE_SSH_LISTEN_ENDPOINTS = "tcp6:22:interface=\\:\\:";
      COWRIE_HONEYPOT_HOSTNAME = config.networking.hostName;
      COWRIE_HONEYPOT_TIMEZONE = config.time.timeZone;
      COWRIE_HONEYPOT_AUTH_CLASS = "AuthRandom";
      COWRIE_SHELL_KERNEL_VERSION = "5.10.0-20-amd64";
      COWRIE_SHELL_KERNEL_BUILD_STRING = "#1 SMP Debian 5.10.158-2 (2022-12-13)";
    }
    // lib.optionalAttrs config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  sops.templates."cowrie-extra-env".content = ''
    COWRIE_OUTPUT_TELEGRAM_ENABLED=true
    COWRIE_OUTPUT_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram-bot/push"}
    COWRIE_OUTPUT_TELEGRAM_CHAT_ID=148111617
  '';
  users.users.cowrie = {
    uid = config.ids.uids.cowrie;
    isSystemUser = true;
    createHome = false;
    home = "/var/lib/cowrie";
    group = "cowrie";
    # for debug
    shell = pkgs.bash;
  };
  users.groups.cowrie = {
    gid = config.ids.gids.cowrie;
  };
  networking.firewall.allowedTCPPorts = [ port ];
}
