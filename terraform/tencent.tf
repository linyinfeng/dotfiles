provider "tencentcloud" {
  secret_id = data.sops_file.terraform.data["tencentcloud.secret-id"]
  secret_key = data.sops_file.terraform.data["tencentcloud.secret-key"]
  region = "ap-shanghai"
}

# TODO lighthouse api not supported yet

locals {
  tencent_ip = data.sops_file.terraform.data["ip.tencent"]
}
