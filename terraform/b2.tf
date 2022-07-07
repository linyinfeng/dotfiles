provider "b2" {
  application_key_id = data.sops_file.terraform.data["b2.application-key-id"]
  application_key    = data.sops_file.terraform.data["b2.application-key"]
}

data "b2_account_info" "main" {
}

output "b2_s3_api_url" {
  value = data.b2_account_info.main.s3_api_url
}
output "b2_download_url" {
  value = data.b2_account_info.main.download_url
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
  value     = b2_application_key.backup.application_key_id
  sensitive = false
}
output "b2_backup_access_key" {
  value     = b2_application_key.backup.application_key
  sensitive = true
}


resource "b2_bucket" "cache" {
  bucket_name = "yinfeng-cache-li7g-com"
  bucket_type = "allPublic" # files avaliable to download

  # keep only the last version of the file
  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }
}
resource "b2_application_key" "cache" {
  key_name  = "cache"
  bucket_id = b2_bucket.cache.id
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
output "b2_cache_key_id" {
  value     = b2_application_key.cache.application_key_id
  sensitive = false
}
output "b2_cache_access_key" {
  value     = b2_application_key.cache.application_key
  sensitive = true
}
