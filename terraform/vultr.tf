provider "vultr" {
  rate_limit  = 700
  retry_limit = 2
}

resource "vultr_instance" "main" {
  plan   = "vc2-1c-0.5gb" # actually an invalid plan
  region = "mia"

  lifecycle {
    ignore_changes = [
      # this plan already removed by vultr
      plan
    ]
  }
}
