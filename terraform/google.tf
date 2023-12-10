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

resource "google_firebase_android_app" "ntfy" {
  provider     = google-beta
  project      = google_firebase_project.ntfy.id
  display_name = "ntfy"
  package_name = "com.li7g.ntfy"
  api_key_id   = google_apikeys_key.ntfy_android.uid
}

resource "google_apikeys_key" "ntfy_android" {
  project      = google_firebase_project.ntfy.id
  name         = "ntfy-android"
  display_name = "ntfy Android"
}

# TODO build customized ntfy apk
# TODO deliver customized apk
