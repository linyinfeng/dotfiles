resource "incus_instance" "nixos" {
  name = "nixos"
  type = "virtual-machine"
  # Manually import the initial image with this alias before the first apply.
  # Subsequent NixOS deployments update the guest in place.
  image = "ostrich-initial"
  profiles = [
    incus_profile.seat.name,
    incus_profile.streaming.name,
    incus_profile.audio.name,
  ]
  # Keep creation stopped; subsequent power changes are operational actions.
  running = false

  config = {
    "limits.cpu"          = "12"
    "limits.memory"       = "16GiB"
    "boot.autostart"      = "true"
    "security.secureboot" = "false"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path     = "/"
      pool     = "local"
      size     = "256GiB"
      "io.bus" = "virtio-blk"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      name    = "eth0"
      network = "incusbr0"
    }
  }

  device {
    name       = "tpm"
    type       = "tpm"
    properties = {}
  }

  lifecycle {
    prevent_destroy = true
    # Switching between NixOS and Windows is an operational action; applying
    # unrelated infrastructure changes must not start or stop this VM.
    ignore_changes = [image, running]
  }
}
