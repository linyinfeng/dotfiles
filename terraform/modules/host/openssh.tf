resource "tls_private_key" "host_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "ssh_host_rsa_key_pub" {
  value     = trimspace(tls_private_key.host_rsa.public_key_openssh)
  sensitive = false
}
output "ssh_host_rsa_key" {
  value     = tls_private_key.host_rsa.private_key_openssh
  sensitive = true
}

resource "tls_private_key" "host_ed25519" {
  algorithm = "ED25519"
}
output "ssh_host_ed25519_key_pub" {
  value     = trimspace(tls_private_key.host_ed25519.public_key_openssh)
  sensitive = false
}
output "ssh_host_ed25519_key" {
  value     = tls_private_key.host_ed25519.private_key_openssh
  sensitive = true
}
