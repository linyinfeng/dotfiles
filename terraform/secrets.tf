variable "terraform_input_path" {
  type = string
}

data "sops_file" "terraform" {
  source_file = var.terraform_input_path
}

data "sops_file" "common" {
  source_file = "../secrets/common.yaml"
}

data "sops_file" "mtl0" {
  source_file = "../secrets/hosts/mtl0-terraform.yaml"
}
