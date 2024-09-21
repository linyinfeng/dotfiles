{
  config,
  pkgs,
  lib,
  ...
}:
let
  njuGitUser = "yinfeng";
  ojRepoName = "online-judge";
  podmanCompose = lib.escapeShellArgs [
    "podman-compose"
    "--podman-build-args"
    "--network host --build-arg=VERSION=staging --build-arg=HOST=https://sicp-staging.li7g.com --build-arg=BASE=/2024/oj/web/"
  ];
in
{
  systemd.services.sicp-staging = {
    preStart = ''
      export TMPDIR="$PWD/tmp"
      mkdir -p "$TMPDIR"

      token=$(cat "$CREDENTIALS_DIRECTORY/token")

      # setup repository
      if [ ! -d "${ojRepoName}" ]; then
        git clone "https://${njuGitUser}:$token@git.nju.edu.cn/nju-sicp/online-judge.git" "${ojRepoName}"
      fi
      pushd "${ojRepoName}"
      git remote set-url origin "https://${njuGitUser}:$token@git.nju.edu.cn/nju-sicp/online-judge.git"

      # update repository
      git fetch origin
      git reset --hard origin/master
      sed -i 's^https://sicp.pascal-lab.net/2024/oj/api^https://sicp-staging.li7g.com/2024/oj/api^g' packages/web/src/config.ts

      # build image
      pushd utils/docker
      ${podmanCompose} \
        --profile all \
        --env-file vars/x86_64.env \
        build
      popd

      popd # from oj repository
    '';
    script = ''
      pushd "${ojRepoName}"
      pushd utils/docker
      ${podmanCompose} \
        --profile all \
        --env-file vars/x86_64.env \
        up
    '';
    path = with pkgs; [
      git
      podman
      podman-compose
    ];
    serviceConfig = {
      TimeoutStartSec = "5min";
      StateDirectory = "sicp-staging";
      WorkingDirectory = "/var/lib/sicp-staging";
      LoadCredential = [
        "token:${config.sops.secrets."nju-git/read-token".path}"
      ];
    };
    requires = [ "podman.socket" ];
    after = [ "podman.socket" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.nginx.virtualHosts."sicp-staging.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/2024/oj/web/".proxyPass = "http://127.0.0.1:8080";
    locations."/2024/oj/api/".proxyPass = "http://127.0.0.1:3000";
  };

  sops.secrets."nju-git/read-token" = {
    sopsFile = config.sops-file.host;
    restartUnits = [ "sicp-staging-build.service" ];
  };
}
