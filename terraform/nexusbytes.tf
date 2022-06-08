# TODO nexusbytes api not supported yet

locals {
  nexusbytes_ip = data.sops_file.terraform.data["ip.nexusbytes"]
}
