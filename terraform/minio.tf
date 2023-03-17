provider "minio" {
  minio_server   = "minio.li7g.com"
  minio_user     = data.sops_file.rica.data["minio.root.user"]
  minio_password = data.sops_file.rica.data["minio.root.password"]
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

# Pastebin

resource "minio_s3_bucket" "atticd" {
  bucket = "atticd"
  acl    = "private"
}

resource "minio_iam_user" "atticd" {
  name = "atticd"
}

output "minio_atticd_key_id" {
  value     = minio_iam_user.atticd.id
  sensitive = false
}
output "minio_atticd_access_key" {
  value     = minio_iam_user.atticd.secret
  sensitive = true
}

data "minio_iam_policy_document" "atticd" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::atticd/*",
    ]
  }
}

resource "minio_iam_policy" "atticd" {
  name   = "atticd"
  policy = data.minio_iam_policy_document.atticd.json
}

resource "minio_iam_user_policy_attachment" "atticd" {
  policy_name = minio_iam_policy.atticd.name
  user_name   = minio_iam_user.atticd.name
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
