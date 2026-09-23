variable "salt" {
  type = string
}

variable "password" {
  type = string
}

resource "shell_sensitive_script" "argon2" {
  lifecycle_commands {
    create = <<EOT
      set -e
      HASHED=$(echo -n "$PASSWORD" | argon2 "$SALT" -id -e)
      jq --null-input \
        --arg hashed "$HASHED" \
        '{"hashed": $hashed}'
    EOT
    delete = <<EOT
      # do nothing
    EOT
  }
  environment = {
    PASSWORD = var.password
    SALT     = var.salt
  }
}
output "hashed_password" {
  value     = shell_sensitive_script.argon2.output.hashed
  sensitive = true
}
