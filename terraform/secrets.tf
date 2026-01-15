variable "terraform_input_path" {
  type = string
}

variable "predefined_secrets_path" {
  type = string
}

data "sops_file" "terraform" {
  source_file = var.terraform_input_path
}


data "sops_file" "predefined" {
  source_file = var.predefined_secrets_path
}
