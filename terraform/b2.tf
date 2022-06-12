provider "b2" {
  application_key_id = data.sops_file.terraform.data["b2.application-key-id"]
  application_key = data.sops_file.terraform.data["b2.application-key"]
}

resource "b2_bucket" "backup" {
  bucket_name = "yinfeng-backup"
  bucket_type = "allPrivate"

  # keep only the last version of the file
  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }
}

resource "b2_application_key" "backup" {
  key_name  = "backup"
  bucket_id = b2_bucket.backup.id
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
  value = b2_application_key.backup.application_key_id
  sensitive = false
}
output "b2_backup_access_key" {
  value = b2_application_key.backup.application_key
  sensitive = true
}
