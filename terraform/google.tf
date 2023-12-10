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

# -------------
# ntfy project
resource "google_project" "ntfy" {
  project_id = "yinfeng-ntfy"
  name       = "ntfy"
}

resource "google_firebase_project" "ntfy" {
  provider = google-beta
  project  = google_project.ntfy.project_id
}

# TODO configure firebase app
# TODO build customized ntfy apk
# TODO deliver customized apk
