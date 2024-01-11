resource "shell_sensitive_script" "generate_dhparam" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory generate_dhparam.XXXXXXXXXX)
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

resource "shell_sensitive_script" "generate_bind_rndc_config" {
  lifecycle_commands {
    create = <<EOT
      set -e

      TMP_DIR=$(mktemp -t --directory generate_bind_rndc_config.XXXXXXXXXX)
      function cleanup {
        rm -r "$TMP_DIR"
      }
      trap cleanup EXIT

      pushd "$TMP_DIR" > /dev/null

      rndc-confgen -c rndc -a -A hmac-sha256 2> /dev/null

      jq --null-input \
        --arg rndc_config "$(cat rndc)" \
        '{"rndc_config": $rndc_config}'

      popd > /dev/null
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
}

output "bind_rndc_config" {
  value     = shell_sensitive_script.generate_bind_rndc_config.output.rndc_config
  sensitive = true
}
