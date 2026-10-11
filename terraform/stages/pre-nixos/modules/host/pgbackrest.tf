resource "random_password" "pgbackrest" {
  length  = 32
  special = false
}

output "pgbackrest_cipher_pass" {
  value     = random_password.pgbackrest.result
  sensitive = true
}
