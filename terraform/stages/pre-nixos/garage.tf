provider "garage" {
  endpoint = "https://garage-admin.li7g.com"
  token    = random_password.garage_admin_token.result
}

# Pastebin

resource "garage_bucket" "pastebin" {
  global_alias    = "pastebin"
  website_enabled = false
  max_size        = 1 * 1024 * 1024 * 1024 # in bytes, 1 GiB
}
resource "garage_key" "pastebin" {
  name = "pastebin"
}
output "garage_pastebin_key_id" {
  value     = garage_key.pastebin.id
  sensitive = false
}
output "garage_pastebin_access_key" {
  value     = garage_key.pastebin.secret_access_key
  sensitive = true
}
resource "garage_bucket_permission" "pastebin" {
  bucket_id     = garage_bucket.pastebin.id
  access_key_id = garage_key.pastebin.id
  read          = true
  write         = true
  owner         = false
}
# TODO retention policy for pastebin

# SICP staging

resource "garage_bucket" "sicp_staging" {
  global_alias    = "sicp-staging"
  website_enabled = false
  max_size        = 1 * 1024 * 1024 * 1024 # in bytes, 1 GiB
}
resource "garage_key" "sicp_staging" {
  name = "sicp-staging"
}
output "garage_sicp_staging_key_id" {
  value     = garage_key.sicp_staging.id
  sensitive = false
}
output "garage_sicp_staging_access_key" {
  value     = garage_key.sicp_staging.secret_access_key
  sensitive = true
}
resource "garage_bucket_permission" "sicp_staging" {
  bucket_id     = garage_bucket.sicp_staging.id
  access_key_id = garage_key.sicp_staging.id
  read          = true
  write         = true
  owner         = false
}
