data "sops_file" "terraform" {
    source_file = "../secrets/terraform-inputs.yaml"
}

data "sops_file" "rica" {
    source_file = "../secrets/rica-terraform.yaml"
}
