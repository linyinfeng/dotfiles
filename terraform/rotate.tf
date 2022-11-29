resource "time_rotating" "rotate_monthly" {
  rotation_days = 30
}

# TODO workaround for replace_triggered_by
# see https://github.com/hashicorp/terraform-provider-time/issues/118
resource "time_static" "rotate_monthly" {
  rfc3339 = time_rotating.rotate_monthly.rfc3339
}

resource "time_rotating" "rotate_weekly" {
  rotation_days = 7
}

resource "time_static" "rotate_weekly" {
  rfc3339 = time_rotating.rotate_weekly.rfc3339
}
