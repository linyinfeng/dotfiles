{
  config,
  pkgs,
  lib,
  ...
}:
let
  port = config.ports.ssh-honeypot;
  cowrieSrc = pkgs.stdenv.mkDerivation {
    inherit (pkgs.nur.repos.linyinfeng.sources.cowrie) pname version src;
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

      mkdir -p state share log honeyfs txtcmds
      rsync --verbose --recursive cowrie-src/var/lib/cowrie/ state/
      rsync --verbose --recursive cowrie-src/honeyfs/ honeyfs/
      if [ -f share/cowrie/fs.pickle ]; then
        echo "backup fs.pickle"
        mv share/cowrie/fs.pickle share/cowrie/fs.pickle.bak
      fi
      rsync --verbose --recursive --delete cowrie-src/share/ share/
      if [ -f share/cowrie/fs.pickle.bak ]; then
        echo "restore fs.pickle"
        mv share/cowrie/fs.pickle.bak share/cowrie/fs.pickle
      fi

      rm -f cowrie-venv/bin/python*
      python3 -m venv cowrie-venv
      source cowrie-venv/bin/activate
      pip install --no-cache-dir --upgrade pip wheel setuptools
      pip install --no-cache-dir --upgrade cffi
      pip install --no-cache-dir --upgrade --requirement cowrie-src/requirements.txt
      pip install --no-cache-dir --upgrade --requirement cowrie-src/requirements-output.txt

      export PYTHONPATH=cowrie-src/src
      python3 -m compileall cowrie-src
      python3 cowrie-venv/bin/twistd --umask=0022 --nodaemon --pidfile= --logfile=- cowrie
    '';
    path = with pkgs; [
      python311
      gcc
      rsync
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "cowrie";
      WorkingDirectory = "/var/lib/cowrie";
      EnvironmentFile = [ config.sops.templates."cowrie-extra-env".path ];
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
    environment = {
      COWRIE_SSH_LISTEN_ENDPOINTS = "tcp6:22:interface=\\:\\:";
      COWRIE_HONEYPOT_STATE_PATH = "state";
      COWRIE_HONEYPOT_SHARE_PATH = "share/cowrie";
      COWRIE_HONEYPOT_LOG_PATH = "log";
      COWRIE_HONEYPOT_CONTENTS_PATH = "honeyfs";
      COWRIE_HONEYPOT_TXTCMDS_PATH = "txtcmds";
      COWRIE_HONEYPOT_HOSTNAME = config.networking.hostName;
      COWRIE_HONEYPOT_TIMEZONE = config.time.timeZone;
      COWRIE_HONEYPOT_AUTH_CLASS = "AuthRandom";
      COWRIE_SHELL_KERNEL_VERSION = "5.10.0-20-amd64";
      COWRIE_SHELL_KERNEL_BUILD_STRING = "#1 SMP Debian 5.10.158-2 (2022-12-13)";
    } // lib.optionalAttrs config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  sops.templates."cowrie-extra-env".content = ''
    COWRIE_OUTPUT_TELEGRAM_ENABLED=true
    COWRIE_OUTPUT_TELEGRAM_BOT_TOKEN=${config.sops.placeholder."telegram-bot/push"}
    COWRIE_OUTPUT_TELEGRAM_CHAT_ID=148111617
  '';
  networking.firewall.allowedTCPPorts = [ port ];
}
