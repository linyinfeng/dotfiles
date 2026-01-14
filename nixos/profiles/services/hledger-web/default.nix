{
  config,
  pkgs,
  lib,
  ...
}:
let
  repoName = "hledger-journal";
in
{
  services.hledger-web = {
    enable = true;
    baseUrl = lib.mkDefault "https://hledger.li7g.com";
    allow = "view";
    port = config.ports.hledger-web;
    extraOptions = [
      "--infer-equity"
      "--verbose-tags"
    ];
    journalFiles = [ "hledger-journal/main.journal" ];
  };
  systemd.services.hledger-web-fetch = {
    script = ''
      token=$(cat "$CREDENTIALS_DIRECTORY/token")
      if [ ! -d "${repoName}" ]; then
        git clone "https://-:$token@github.com/linyinfeng/${repoName}.git" "${repoName}"
      fi
      cd "${repoName}"
      git remote set-url origin "https://-:$token@github.com/linyinfeng/${repoName}.git"
      while true; do
        set +e
        git fetch origin
        git reset --hard origin/main
        set -e
        sleep 60
      done
    '';
    path = with pkgs; [ git ];
    serviceConfig = {
      User = config.users.users.hledger.name;
      Group = config.users.groups.hledger.name;
      WorkingDirectory = config.services.hledger-web.stateDir;
      LoadCredential = [ "token:${config.sops.secrets."github_token_hledger".path}" ];
    };
    before = [ "hledger-web.service" ];
    requiredBy = [ "hledger-web.service" ];
  };
  services.nginx.virtualHosts."hledger.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.hledger-web}";
      extraConfig = ''
        auth_basic "hledger";
        auth_basic_user_file ${config.sops.templates."hledger-auth-file".path};
      '';
    };
  };
  systemd.services.nginx.restartTriggers = [ config.sops.templates."hledger-auth-file".file ];
  sops.templates."hledger-auth-file" = {
    content = ''
      ${config.sops.placeholder."hledger_username"}:${config.sops.placeholder."hledger_hashed_password"}
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."github_token_hledger" = {
    predefined.enable = true;
    restartUnits = [ "hledger-web-fetch.service" ];
  };
  sops.secrets."hledger_username" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
  sops.secrets."hledger_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nginx.service" ];
  };
  services.restic.backups.b2.paths = [ "/var/lib/hledger" ];
}
