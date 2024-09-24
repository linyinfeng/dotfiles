provider "gitlab" {
  alias    = "nju"
  base_url = "https://git.nju.edu.cn/api/v4"
  token    = data.sops_file.terraform.data["gitlab.nju.token"]
}

data "gitlab_project" "sicp_online_judge" {
  provider            = gitlab.nju
  path_with_namespace = "nju-sicp/online-judge"
}

resource "gitlab_user_runner" "sicp_online_judge_docker_runner" {
  provider = gitlab.nju

  runner_type = "project_type"
  project_id  = data.gitlab_project.sicp_online_judge.id

  description = "Runner support docker in docker"
  tag_list    = ["docker", "docker-in-docker"]
  untagged    = false
}

output "gitlab_sicp_oj_docker_runner_token" {
  value     = gitlab_user_runner.sicp_online_judge_docker_runner.token
  sensitive = true
}
