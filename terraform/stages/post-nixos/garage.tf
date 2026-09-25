provider "garage" {
  endpoint = "https://garage-admin.li7g.com"
  token    = local.garage_admin_token
}

# Pastebin

resource "garage_bucket" "pastebin" {
  global_alias    = "pastebin"
  website_enabled = false
  max_size        = 1 * 1024 * 1024 * 1024 # in bytes, 1 GiB
}
resource "garage_key" "pastebin" {
  name = "pastebin"
  # the access key id is public (lib/data/data.json); only the secret is sensitive
  id                = nonsensitive(local.garage_keys.pastebin.id)
  secret_access_key = local.garage_keys.pastebin.secret
}
resource "garage_bucket_permission" "pastebin" {
  bucket_id     = garage_bucket.pastebin.id
  access_key_id = nonsensitive(garage_key.pastebin.id)
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
  name              = "sicp-staging"
  id                = nonsensitive(local.garage_keys.sicp_staging.id)
  secret_access_key = local.garage_keys.sicp_staging.secret
}
resource "garage_bucket_permission" "sicp_staging" {
  bucket_id     = garage_bucket.sicp_staging.id
  access_key_id = nonsensitive(garage_key.sicp_staging.id)
  read          = true
  write         = true
  owner         = false
}

# Per-host restic backup buckets

module "host_backup" {
  source = "./modules/host-backup"

  for_each   = toset(local.garage_backup_hosts)
  name       = each.key
  key_id     = nonsensitive(local.garage_keys.hosts[each.key].id)
  key_secret = local.garage_keys.hosts[each.key].secret
}
