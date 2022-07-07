resource "random_password" "restic" {
  length           = 32
  special = false
}

output "restic_password" {
    value = random_password.restic.result
    sensitive = true
}
