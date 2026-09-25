variable "name" {
  type = string
}
variable "key_id" {
  type = string
}
variable "key_secret" {
  type      = string
  sensitive = true
}

resource "garage_bucket" "backup" {
  global_alias    = "backup-${var.name}"
  website_enabled = false
}
resource "garage_key" "backup" {
  name              = "backup-${var.name}"
  id                = nonsensitive(var.key_id)
  secret_access_key = var.key_secret
}
resource "garage_bucket_permission" "backup" {
  bucket_id     = garage_bucket.backup.id
  access_key_id = nonsensitive(garage_key.backup.id)
  read          = true
  write         = true
  owner         = false
}
