# Backup bucket key material; post-nixos registers it with the Garage admin API.

resource "random_id" "backup_key_id" {
  byte_length = 12
}
resource "random_id" "backup_key_secret" {
  byte_length = 32
}

output "garage_backup_key_id" {
  value = "GK${random_id.backup_key_id.hex}"
}
output "garage_backup_access_key" {
  value     = random_id.backup_key_secret.hex
  sensitive = true
}
