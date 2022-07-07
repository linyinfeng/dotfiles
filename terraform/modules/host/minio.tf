# Backup bucket

resource "minio_s3_bucket" "backup" {
  bucket = "backup-${var.name}"
  acl    = "private"
}

resource "minio_iam_user" "backup" {
  name = "backup-${var.name}"
}

output "minio_backup_key_id" {
  value     = minio_iam_user.backup.id
  sensitive = false
}
output "minio_backup_access_key" {
  value     = minio_iam_user.backup.secret
  sensitive = true
}

data "minio_iam_policy_document" "backup" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::backup-${var.name}/*",
    ]
  }
}

resource "minio_iam_policy" "backup" {
  name   = "backup-${var.name}"
  policy = data.minio_iam_policy_document.backup.json
}

resource "minio_iam_user_policy_attachment" "backup" {
  policy_name = minio_iam_policy.backup.name
  user_name   = minio_iam_user.backup.name
}
