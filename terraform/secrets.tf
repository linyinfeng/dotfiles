data "sops_file" "terraform" {
    source_file = "../secrets/terraform.yaml"
}

data "sops_file" "rica" {
    source_file = "../secrets/rica.yaml"
}
