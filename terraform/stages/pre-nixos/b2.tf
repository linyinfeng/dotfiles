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
module "b2_s3_api_url" {
  source = "matti/urlparse/external"
  url    = data.b2_account_info.main.s3_api_url
}
module "b2_download_url" {
  source = "matti/urlparse/external"
  url    = data.b2_account_info.main.download_url
}
output "b2_s3_api_host" {
  value = module.b2_s3_api_url.host
}
output "b2_s3_region" {
  value = regex("^s3.([a-z0-9\\-]+).backblazeb2.com$", module.b2_s3_api_url.host)[0]
}

resource "b2_application_key" "manage" {
  # key for data management
  key_name = "manage"
  # read and write to all buckets
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

resource "b2_bucket" "cache" {
  bucket_name = "cache-li7g-com"
  bucket_type = "allPublic" # files avaliable to download

  bucket_info = {
    cache-control = "public, max-age=604800"
  }

  # keep only the last version of the file
  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }
}
resource "b2_application_key" "cache" {
  key_name   = "cache"
  bucket_ids = [b2_bucket.cache.id]
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
output "b2_cache_bucket_name" {
  value     = b2_bucket.cache.bucket_name
  sensitive = false
}
output "b2_cache_key_id" {
  value     = b2_application_key.cache.application_key_id
  sensitive = false
}
output "b2_cache_access_key" {
  value     = b2_application_key.cache.application_key
  sensitive = true
}
resource "b2_bucket_file_version" "nix_cache_info" {
  bucket_id    = b2_bucket.cache.bucket_id
  file_name    = "nix-cache-info"
  content_type = "text/x-nix-cache-info"
  source       = "${path.module}/resources/nix-cache-info"
}

resource "b2_bucket" "mastodon_media" {
  # prefix with yinfeng- to prevent name conflict
  # the name mastodon-media and mastodon is already taken
  bucket_name = "yinfeng-mastodon-media"
  bucket_type = "allPublic"

  # keep only the last version of the file
  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }

  cors_rules {
    cors_rule_name = "allow-media-on-li7g-com"
    allowed_operations = [
      "s3_head",
      "b2_download_file_by_id",
      "b2_download_file_by_name",
      "s3_get"
    ]
    allowed_origins = [
      "https://*.li7g.com"
    ]
    max_age_seconds = 86400
  }
}
resource "b2_application_key" "mastodon_media" {
  key_name   = "mastodon-media"
  bucket_ids = [b2_bucket.mastodon_media.id]
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
output "b2_mastodon_media_bucket_name" {
  value     = b2_bucket.mastodon_media.bucket_name
  sensitive = false
}
output "b2_mastodon_media_key_id" {
  value     = b2_application_key.mastodon_media.application_key_id
  sensitive = false
}
output "b2_mastodon_media_access_key" {
  value     = b2_application_key.mastodon_media.application_key
  sensitive = true
}
