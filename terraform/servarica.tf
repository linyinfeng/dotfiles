locals {
  rica_ip = data.sops_file.terraform.data["ip.rica"]
}
