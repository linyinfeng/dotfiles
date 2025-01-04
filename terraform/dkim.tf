resource "shell_sensitive_script" "generate_dkim" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory dkim.XXXXXXXXXX)
      cleanup() {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      openssl genrsa -out dkim_private.pem 2048 2> /dev/null
      openssl rsa -in dkim_private.pem -pubout -outform der 2>/dev/null | openssl base64 -A > dkim.public

      jq --null-input \
        --arg dkim_public_key "$(cat dkim.public)" \
        --arg dkim_private_pem "$(cat dkim_private.pem)" \
        '{"dkim_algorithm": "rsa", "dkim_public_key": $dkim_public_key, "dkim_private_pem": $dkim_private_pem}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
}

locals {
  dkim_algorithm  = shell_sensitive_script.generate_dkim.output.dkim_algorithm
  dkim_public_key = shell_sensitive_script.generate_dkim.output.dkim_public_key
}

output "dkim_private_pem" {
  value     = shell_sensitive_script.generate_dkim.output.dkim_private_pem
  sensitive = true
}
