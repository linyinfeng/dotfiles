resource "wireguard_asymmetric_key" "host" {
}

output "wireguard_public_key" {
    value = wireguard_asymmetric_key.host.public_key
}
output "wireguard_private_key" {
    value = wireguard_asymmetric_key.host.private_key
    sensitive = true
}
