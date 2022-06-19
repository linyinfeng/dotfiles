provider "tencentcloud" {
  secret_id  = data.sops_file.terraform.data["tencentcloud.secret-id"]
  secret_key = data.sops_file.terraform.data["tencentcloud.secret-key"]
  region     = "ap-shanghai"
}
