resource "shell_sensitive_script" "generate_dhparam" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory zerotier-dkim.XXXXXXXXXX)
      function cleanup {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      openssl dhparam -out dhparam.pem 4096 2> /dev/null

      jq --null-input \
        --arg dhparam_pem "$(cat dhparam.pem)" \
        '{"dhparam_pem": $dhparam_pem}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
}

output "dhparam_pem" {
  value     = shell_sensitive_script.generate_dhparam.output.dhparam_pem
  sensitive = true
}
