resource "random_uuid" "secure_boot_signature_owner_guid" {
}
output "secure_boot_signature_owner_guid" {
  value = random_uuid.secure_boot_signature_owner_guid.result
}

resource "tls_private_key" "secure_boot_platform_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_cert_request" "secure_boot_platform_key" {
  private_key_pem = tls_private_key.secure_boot_platform_key.private_key_pem
  subject {
    common_name = "Yinfeng Secure Boot Platform Key"
  }
}
resource "tls_locally_signed_cert" "secure_boot_platform_key" {
  cert_request_pem   = tls_cert_request.secure_boot_platform_key.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  is_ca_certificate     = true
  validity_period_hours = 87600 # 10 years
  early_renewal_hours   = 43800 # 5  year
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
}
output "secure_boot_pk_cert_pem" {
  value     = tls_locally_signed_cert.secure_boot_platform_key.cert_pem
  sensitive = false
}
output "secure_boot_pk_private_key" {
  value     = tls_private_key.secure_boot_platform_key.private_key_pem
  sensitive = true
}
output "secure_boot_pk_private_key_pkcs8" {
  value     = tls_private_key.secure_boot_platform_key.private_key_pem_pkcs8
  sensitive = true
}
module "secure_boot_pk_signature_list" {
  source               = "./modules/secure-boot-signature-list"
  signature_owner_guid = random_uuid.secure_boot_signature_owner_guid.result
  cert                 = tls_locally_signed_cert.secure_boot_platform_key.cert_pem
  efi_variable         = "PK"
  sign_by_cert         = tls_locally_signed_cert.secure_boot_platform_key.cert_pem
  sign_by_key          = tls_private_key.secure_boot_platform_key.private_key_pem
}
output "secure_boot_pk_esl_base64" {
  value     = module.secure_boot_pk_signature_list.efi_signature_list_base64
  sensitive = false
}
output "secure_boot_pk_signed_esl_base64" {
  value     = module.secure_boot_pk_signature_list.signed_efi_signature_list_base64
  sensitive = false
}

resource "tls_private_key" "secure_boot_key_exchange_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_cert_request" "secure_boot_key_exchange_key" {
  private_key_pem = tls_private_key.secure_boot_key_exchange_key.private_key_pem
  subject {
    common_name = "Yinfeng Secure Boot Key Exchange Key"
  }
}
resource "tls_locally_signed_cert" "secure_boot_key_exchange_key" {
  cert_request_pem   = tls_cert_request.secure_boot_key_exchange_key.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600 # 10 years
  early_renewal_hours   = 43800 # 5  year
  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing"
  ]
}
output "secure_boot_kek_cert_pem" {
  value     = tls_locally_signed_cert.secure_boot_key_exchange_key.cert_pem
  sensitive = false
}
output "secure_boot_kek_private_key" {
  value     = tls_private_key.secure_boot_key_exchange_key.private_key_pem
  sensitive = true
}
output "secure_boot_kek_private_key_pkcs8" {
  value     = tls_private_key.secure_boot_key_exchange_key.private_key_pem_pkcs8
  sensitive = true
}
module "secure_boot_kek_signature_list" {
  source               = "./modules/secure-boot-signature-list"
  signature_owner_guid = random_uuid.secure_boot_signature_owner_guid.result
  cert                 = tls_locally_signed_cert.secure_boot_key_exchange_key.cert_pem
  efi_variable         = "KEK"
  sign_by_cert         = tls_locally_signed_cert.secure_boot_platform_key.cert_pem
  sign_by_key          = tls_private_key.secure_boot_platform_key.private_key_pem
}
output "secure_boot_kek_esl_base64" {
  value     = module.secure_boot_kek_signature_list.efi_signature_list_base64
  sensitive = false
}
output "secure_boot_kek_signed_esl_base64" {
  value     = module.secure_boot_kek_signature_list.signed_efi_signature_list_base64
  sensitive = false
}

resource "tls_private_key" "secure_boot_database_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_cert_request" "secure_boot_database_key" {
  private_key_pem = tls_private_key.secure_boot_database_key.private_key_pem
  subject {
    common_name = "Yinfeng Secure Boot Signature Database Key"
  }
}
resource "tls_locally_signed_cert" "secure_boot_database_key" {
  cert_request_pem   = tls_cert_request.secure_boot_database_key.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87600 # 10 years
  early_renewal_hours   = 43800 # 5  year
  allowed_uses = [
    "digital_signature"
  ]
}
output "secure_boot_db_cert_pem" {
  value     = tls_locally_signed_cert.secure_boot_database_key.cert_pem
  sensitive = false
}
output "secure_boot_db_private_key" {
  value     = tls_private_key.secure_boot_database_key.private_key_pem
  sensitive = true
}
output "secure_boot_db_private_key_pkcs8" {
  value     = tls_private_key.secure_boot_database_key.private_key_pem_pkcs8
  sensitive = true
}
module "secure_boot_db_signature_list" {
  source               = "./modules/secure-boot-signature-list"
  signature_owner_guid = random_uuid.secure_boot_signature_owner_guid.result
  cert                 = tls_locally_signed_cert.secure_boot_database_key.cert_pem
  efi_variable         = "db"
  sign_by_cert         = tls_locally_signed_cert.secure_boot_key_exchange_key.cert_pem
  sign_by_key          = tls_private_key.secure_boot_key_exchange_key.private_key_pem
}
output "secure_boot_db_esl_base64" {
  value     = module.secure_boot_db_signature_list.efi_signature_list_base64
  sensitive = false
}
output "secure_boot_db_signed_esl_base64" {
  value     = module.secure_boot_db_signature_list.signed_efi_signature_list_base64
  sensitive = false
}
