provider "gitlab" {
  base_url = "https://git.nju.edu.cn/api/v4"
  token    = data.sops_file.terraform.data["gitlab.nju.token"]
}
