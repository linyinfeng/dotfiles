resource "random_id" "garage_pastebin_key_id" {
  byte_length = 12
}
resource "random_id" "garage_pastebin_key_secret" {
  byte_length = 32
}

# Pastebin

output "garage_pastebin_key_id" {
  value = "GK${random_id.garage_pastebin_key_id.hex}"
}
output "garage_pastebin_access_key" {
  value     = random_id.garage_pastebin_key_secret.hex
  sensitive = true
}

# SICP staging

resource "random_id" "garage_sicp_staging_key_id" {
  byte_length = 12
}
resource "random_id" "garage_sicp_staging_key_secret" {
  byte_length = 32
}
output "garage_sicp_staging_key_id" {
  value = "GK${random_id.garage_sicp_staging_key_id.hex}"
}
output "garage_sicp_staging_access_key" {
  value     = random_id.garage_sicp_staging_key_secret.hex
  sensitive = true
}

# non-sensitive companion of garage_keys_json (sensitive values cannot be for_each keys)
output "garage_backup_hosts_json" {
  value = jsonencode(keys(local.hosts))
}

# key material lives here because NixOS consumes it; post-nixos only registers it
output "garage_keys_json" {
  value = jsonencode({
    pastebin = {
      id     = "GK${random_id.garage_pastebin_key_id.hex}"
      secret = random_id.garage_pastebin_key_secret.hex
    }
    sicp_staging = {
      id     = "GK${random_id.garage_sicp_staging_key_id.hex}"
      secret = random_id.garage_sicp_staging_key_secret.hex
    }
    hosts = {
      for name, outputs in module.hosts : name => {
        id     = outputs.garage_backup_key_id
        secret = outputs.garage_backup_access_key
      }
    }
  })
  sensitive = true
}
