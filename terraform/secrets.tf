data "sops_file" "terraform" {
  source_file = "../secrets/terraform-inputs.yaml"
}

data "sops_file" "mtl0" {
  source_file = "../secrets/hosts/mtl0-terraform.yaml"
}
