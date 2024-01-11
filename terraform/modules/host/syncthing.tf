resource "shell_sensitive_script" "generate_syncthing_config" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory generate-syncthing-config.XXXXXXXXXX)
      function cleanup {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      DEVICE_ID=$(
        syncthing generate --skip-port-probing --no-default-folder --config . |\
          grep --only-matching --perl-regex 'Device ID: \K[A-Z0-9-]+'
      )
      jq --null-input \
        --arg device_id "$DEVICE_ID" \
        --arg cert_pem "$(cat cert.pem)" \
        --arg key_pem "$(cat key.pem)" \
        '{"device_id": $device_id, "cert_pem": $cert_pem, "key_pem": $key_pem}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
}

output "syncthing_device_id" {
  # TODO might be unsafe
  value     = nonsensitive(shell_sensitive_script.generate_syncthing_config.output.device_id)
  sensitive = false
}
output "syncthing_cert_pem" {
  value     = shell_sensitive_script.generate_syncthing_config.output.cert_pem
  sensitive = true
}
output "syncthing_key_pem" {
  value     = shell_sensitive_script.generate_syncthing_config.output.key_pem
  sensitive = true
}
