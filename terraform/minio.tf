provider "minio" {
  minio_server   = "minio.li7g.com"
  minio_user     = data.sops_file.mtl0.data["minio.root.user"]
  minio_password = data.sops_file.mtl0.data["minio.root.password"]
  minio_ssl      = true
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

# Cache test

resource "minio_s3_bucket" "cache_test" {
  bucket = "cache-test"
  acl    = "private"
}

resource "minio_iam_user" "cache_test" {
  name = "cache-test"
}

output "minio_cache_test_key_id" {
  value     = minio_iam_user.cache_test.id
  sensitive = false
}
output "minio_cache_test_access_key" {
  value     = minio_iam_user.cache_test.secret
  sensitive = true
}

data "minio_iam_policy_document" "cache_test" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::cache-test/*",
    ]
  }
}

resource "minio_iam_policy" "cache_test" {
  name   = "cache-test"
  policy = data.minio_iam_policy_document.cache_test.json
}

resource "minio_iam_user_policy_attachment" "cache_test" {
  policy_name = minio_iam_policy.cache_test.name
  user_name   = minio_iam_user.cache_test.name
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

# SICP staging

resource "minio_s3_bucket" "sicp_staging" {
  bucket = "sicp-staging"
  acl    = "private"
}

resource "minio_iam_user" "sicp_staging" {
  name = "sicp-staging"
}

output "minio_sicp_staging_key_id" {
  value     = minio_iam_user.sicp_staging.id
  sensitive = false
}
output "minio_sicp_staging_access_key" {
  value     = minio_iam_user.sicp_staging.secret
  sensitive = true
}

data "minio_iam_policy_document" "sicp_staging" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::sicp-staging/*",
    ]
  }
}

resource "minio_iam_policy" "sicp_staging" {
  name   = "sicp-staging"
  policy = data.minio_iam_policy_document.sicp_staging.json
}

resource "minio_iam_user_policy_attachment" "sicp_staging" {
  policy_name = minio_iam_policy.sicp_staging.name
  user_name   = minio_iam_user.sicp_staging.name
}
