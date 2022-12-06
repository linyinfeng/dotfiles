provider "minio" {
  minio_server     = "minio.li7g.com"
  minio_user = data.sops_file.rica.data["minio.root.user"]
  minio_password = data.sops_file.rica.data["minio.root.password"]
  minio_ssl        = true
}

# Storage for cache.li7g.com
resource "minio_s3_bucket" "cache" {
  bucket = "cache"
}

resource "minio_s3_bucket_policy" "cache" {
  bucket = minio_s3_bucket.cache.bucket
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:GetObject",
          "s3:GetBucketLocation"
        ],
        "Resource" = [
          "arn:aws:s3:::${minio_s3_bucket.cache.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.cache.bucket}/*"
        ],
        "Principal" = {
          "AWS" = ["*"]
        },
      }
    ]
  })
}

resource "minio_s3_object" "nix_cache_info" {
  depends_on   = [minio_s3_bucket.cache]
  bucket_name  = minio_s3_bucket.cache.bucket
  object_name  = "nix-cache-info"
  content_type = "text/x-nix-cache-info"
  content      = file("${path.module}/resources/nix-cache-info")
}

resource "minio_iam_user" "cache" {
  name = "cache"
}

output "minio_cache_key_id" {
  value     = minio_iam_user.cache.id
  sensitive = false
}
output "minio_cache_access_key" {
  value     = minio_iam_user.cache.secret
  sensitive = true
}

data "minio_iam_policy_document" "cache" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::cache/*",
    ]
  }
}

resource "minio_iam_policy" "cache" {
  name   = "cache"
  policy = data.minio_iam_policy_document.cache.json
}

resource "minio_iam_user_policy_attachment" "cache" {
  policy_name = minio_iam_policy.cache.name
  user_name   = minio_iam_user.cache.name
}

# Pastebin

resource "minio_s3_bucket" "pastebin" {
  bucket = "pastebin"
  acl    = "private"
  quota  = 1 * 1024 * 1024 * 1024 # in bytes, 1 GiB
}

resource "minio_iam_user" "pastebin" {
  name = "pastebin"
}

output "minio_pastebin_key_id" {
  value     = minio_iam_user.pastebin.id
  sensitive = false
}
output "minio_pastebin_access_key" {
  value     = minio_iam_user.pastebin.secret
  sensitive = true
}

data "minio_iam_policy_document" "pastebin" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::pastebin/*",
    ]
  }
}

resource "minio_iam_policy" "pastebin" {
  name   = "pastebin"
  policy = data.minio_iam_policy_document.pastebin.json
}

resource "minio_iam_user_policy_attachment" "pastebin" {
  policy_name = minio_iam_policy.pastebin.name
  user_name   = minio_iam_user.pastebin.name
}

resource "minio_ilm_policy" "pastebin_expire_1d" {
  bucket = minio_s3_bucket.pastebin.bucket

  rule {
    id         = "expire-7d"
    expiration = "7d"
  }
}

# Loki

resource "minio_s3_bucket" "loki" {
  bucket = "loki"
  acl    = "private"
}

resource "minio_s3_bucket" "loki-ruler" {
  bucket = "loki-ruler"
  acl    = "private"
}

resource "minio_iam_user" "loki" {
  name = "loki"
}

output "minio_loki_key_id" {
  value     = minio_iam_user.loki.id
  sensitive = false
}
output "minio_loki_access_key" {
  value     = minio_iam_user.loki.secret
  sensitive = true
}

data "minio_iam_policy_document" "loki" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::loki/*",
      "arn:aws:s3:::loki-ruler/*",
    ]
  }
}

resource "minio_iam_policy" "loki" {
  name   = "loki"
  policy = data.minio_iam_policy_document.loki.json
}

resource "minio_iam_user_policy_attachment" "loki" {
  policy_name = minio_iam_policy.loki.name
  user_name   = minio_iam_user.loki.name
}

# Metrics

resource "minio_iam_user" "metrics" {
  name = "metrics"
}

output "minio_metrics_key_id" {
  value     = minio_iam_user.metrics.id
  sensitive = false
}
output "minio_metrics_access_key" {
  value     = minio_iam_user.metrics.secret
  sensitive = true
}

data "minio_iam_policy_document" "metrics" {
  statement {
    actions = [
      "admin:Prometheus",
    ]
    resources = [
      "arn:aws:s3:::*",
    ]
  }
}

resource "minio_iam_policy" "metrics" {
  name   = "metrics"
  policy = data.minio_iam_policy_document.metrics.json
}

resource "minio_iam_user_policy_attachment" "metrics" {
  policy_name = minio_iam_policy.metrics.name
  user_name   = minio_iam_user.metrics.name
}

resource "shell_sensitive_script" "minio_metrics_generate_prometheus_config" {
  lifecycle_commands {
    create = <<EOT
      set -e

      mc alias set minio-metrics https://minio.li7g.com "$KEY_ID" "$ACCESS_KEY" >&2
      mc admin prometheus generate minio-metrics --json
      mc alias remove minio-metrics >&2
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  environment = {
    KEY_ID = minio_iam_user.metrics.id
  }
  sensitive_environment = {
    ACCESS_KEY = minio_iam_user.metrics.secret
  }
}
output "minio_metrics_bearer_token" {
  value     = shell_sensitive_script.minio_metrics_generate_prometheus_config.output.bearerToken
  sensitive = true
}

# Synapse media storage

resource "minio_s3_bucket" "synapse_media" {
  bucket = "synapse-media"
  acl    = "private"
}

resource "minio_iam_user" "synapse_media" {
  name = "synapse-media"
}

output "minio_synapse_media_key_id" {
  value     = minio_iam_user.synapse_media.id
  sensitive = false
}
output "minio_synapse_media_access_key" {
  value     = minio_iam_user.synapse_media.secret
  sensitive = true
}

data "minio_iam_policy_document" "synapse_media" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::synapse-media/*",
    ]
  }
}

resource "minio_iam_policy" "synapse_media" {
  name   = "synapse-media"
  policy = data.minio_iam_policy_document.synapse_media.json
}

resource "minio_iam_user_policy_attachment" "synapse_media" {
  policy_name = minio_iam_policy.synapse_media.name
  user_name   = minio_iam_user.synapse_media.name
}

# Mastodon media storage

resource "minio_s3_bucket" "mastodon_media" {
  bucket = "mastodon-media"
  acl    = "private"
}

resource "minio_iam_user" "mastodon_media" {
  name = "mastodon-media"
}

output "minio_mastodon_media_key_id" {
  value     = minio_iam_user.mastodon_media.id
  sensitive = false
}
output "minio_mastodon_media_access_key" {
  value     = minio_iam_user.mastodon_media.secret
  sensitive = true
}

data "minio_iam_policy_document" "mastodon_media" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::mastodon-media/*",
    ]
  }
}

resource "minio_iam_policy" "mastodon_media" {
  name   = "mastodon-media"
  policy = data.minio_iam_policy_document.mastodon_media.json
}

resource "minio_iam_user_policy_attachment" "mastodon_media" {
  policy_name = minio_iam_policy.mastodon_media.name
  user_name   = minio_iam_user.mastodon_media.name
}

resource "minio_s3_bucket_policy" "mastodon_media_bucket" {
  bucket = minio_s3_bucket.mastodon_media.bucket
  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::mastodon-media/*"
            ]
        }
    ]
}
EOT
}
