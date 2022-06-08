provider "minio" {
  minio_server = "minio.li7g.com"
  minio_access_key = data.sops_file.rica.data["minio.root.user"]
  minio_secret_key = data.sops_file.rica.data["minio.root.password"]
  minio_ssl = true
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
  content      = <<EOF
StoreDir: /nix/store
WantMassQuery: 1
Priority: 50
EOF
}

resource "minio_iam_user" "cache" {
  name = "cache"
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

# Backup bucket

resource "minio_s3_bucket" "backup" {
  bucket = "backup"
  acl    = "private"
}

resource "minio_iam_user" "backup" {
  name = "backup"
}

data "minio_iam_policy_document" "backup" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::backup/*",
    ]
  }
}

resource "minio_iam_policy" "backup" {
  name   = "backup"
  policy = data.minio_iam_policy_document.backup.json
}

resource "minio_iam_user_policy_attachment" "backup" {
  policy_name = minio_iam_policy.backup.name
  user_name   = minio_iam_user.backup.name
}


# Pastebin

resource "minio_s3_bucket" "pastebin" {
  bucket = "pastebin"
  acl    = "private"
}

resource "minio_iam_user" "pastebin" {
  name = "pastebin"
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
    id         = "expire-1d"
    expiration = "1d"
  }
}

# Metrics

resource "minio_iam_user" "metrics" {
  name = "metrics"
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
