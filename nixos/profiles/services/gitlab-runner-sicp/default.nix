{ config, ... }:
{
  services.gitlab-runner = {
    enable = true;
    services = {
      sicp-oj-docker = {
        authenticationTokenConfigFile = config.sops.templates."gitlab-runner-sicp-oj-docker-auth".path;
        dockerImage = "alpine:stable";
        dockerVolumes = [
          "/run/docker.sock:/run/docker.sock"
        ];
        tagList = [ "docker" ];
      };
    };
  };
  systemd.services.gitlab-runner.restartTriggers = [
    config.sops.templates."gitlab-runner-sicp-oj-docker-auth".content
  ];

  sops.templates."gitlab-runner-sicp-oj-docker-auth".content = ''
    CI_SERVER_URL="https://git.nju.edu.cn"
    CI_SERVER_TOKEN="${config.sops.placeholder."gitlab_sicp_oj_docker_runner_token"}"
  '';
  sops.secrets."gitlab_sicp_oj_docker_runner_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "gitlab-runner.service" ];
  };
}
