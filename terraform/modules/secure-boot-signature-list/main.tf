variable "signature_owner_guid" {
  type = string
}

variable "cert" {
  type = string
}

variable "efi_variable" {
  type = string
}

variable "sign_by_cert" {
  type = string
}

variable "sign_by_key" {
  type      = string
  sensitive = true
}

# not sensitive
resource "shell_script" "genertate_efi_sigature_list" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory generate-efi-signature-list.XXXXXXXXXX)
      function cleanup {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      echo "$CERTIFICATE_PEM" > cert.crt
      cert-to-efi-sig-list -g "${var.signature_owner_guid}" cert.crt cert.esl

      jq --null-input \
        --arg efi_signature_list_base64 "$(cat cert.esl | base64)" \
        '{"efi_signature_list_base64": $efi_signature_list_base64}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  environment = {
    CERTIFICATE_PEM = var.cert
  }
}
output "efi_signature_list_base64" {
  value = shell_script.genertate_efi_sigature_list.output.efi_signature_list_base64
}

resource "shell_script" "generate_signed_efi_sigature_list" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory generate-signature-list.XXXXXXXXXX)
      function cleanup {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      echo "$EFI_SIGNATURE_BASE64" | base64 --decode > cert.esl
      echo "$SIGNER_CERTIFICATE_PEM" > signer.crt
      echo "$SIGNER_CERTIFICATE_KEY" > signer.key

      # -a: appending instead of replacement
      sign-efi-sig-list -a -g "${var.signature_owner_guid}" -k signer.key -c signer.crt ${var.efi_variable} cert.esl cert.auth

      jq --null-input \
        --arg signed_efi_signature_list_base64 "$(cat cert.auth | base64)" \
        '{"signed_efi_signature_list_base64": $signed_efi_signature_list_base64}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  environment = {
    EFI_SIGNATURE_BASE64   = shell_script.genertate_efi_sigature_list.output.efi_signature_list_base64
    SIGNER_CERTIFICATE_PEM = var.sign_by_cert
  }
  sensitive_environment = {
    SIGNER_CERTIFICATE_KEY = var.sign_by_key
  }
}
output "signed_efi_signature_list_base64" {
  value = shell_script.generate_signed_efi_sigature_list.output.signed_efi_signature_list_base64
}
