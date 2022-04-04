provider "tencentcloud" {
  region = "ap-shanghai"
}

# TODO lighthouse api not supported yet

variable "tencent_ip" {
  type      = string
  sensitive = true
}
