provider "alicloud" {

  access_key = data.sops_file.terraform.data["aliyun.access-key-id"]
  secret_key = data.sops_file.terraform.data["aliyun.access-key-secret"]
  region     = var.alicloud_region
}

variable "alicloud_region" {
  default = "cn-shenzhen"
}
