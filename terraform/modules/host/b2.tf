resource "b2_bucket" "backup" {
  bucket_name = "yinfeng-backup-${var.name}"
  bucket_type = "allPrivate"

  # keep only the last version of the file
  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }
}

resource "b2_application_key" "backup" {
  key_name   = "backup-${var.name}"
  bucket_ids = [b2_bucket.backup.id]
  capabilities = [
    "deleteFiles",
    "listAllBucketNames",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeFiles"
  ]
}
output "b2_backup_key_id" {
  value     = b2_application_key.backup.application_key_id
  sensitive = false
}
output "b2_backup_access_key" {
  value     = b2_application_key.backup.application_key
  sensitive = true
}
