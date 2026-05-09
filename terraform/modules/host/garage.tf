# Backup bucket


resource "garage_bucket" "backup" {
  global_alias    = "backup-${var.name}"
  website_enabled = false
}
resource "garage_key" "backup" {
  name = "backup-${var.name}"
}
output "garage_backup_key_id" {
  value     = garage_key.backup.id
  sensitive = false
}
output "garage_backup_access_key" {
  value     = garage_key.backup.secret_access_key
  sensitive = true
}
resource "garage_bucket_permission" "backup" {
  bucket_id     = garage_bucket.backup.id
  access_key_id = garage_key.backup.id
  read          = true
  write         = true
  owner         = false
}
