provider "google" {
  credentials = jsonencode(yamldecode(data.sops_file.terraform.raw).google)
  project     = "yinfeng-terraform" # defailt project
}

provider "google-beta" {
  credentials = jsonencode(yamldecode(data.sops_file.terraform.raw).google)
  project     = "yinfeng-terraform" # defailt project
}

resource "google_project" "main" {
  project_id = "yinfeng-terraform"
  name       = "terraform"
}
