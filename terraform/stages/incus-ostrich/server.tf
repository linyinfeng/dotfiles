locals {
  # Reuse the same public authentication configuration as the installation seed.
  data = jsondecode(file("${path.module}/../../../lib/data/data.json"))
}

resource "incus_server" "ostrich" {
  config = local.data.zitadel_incus_server_config

  lifecycle {
    prevent_destroy = true
  }
}
