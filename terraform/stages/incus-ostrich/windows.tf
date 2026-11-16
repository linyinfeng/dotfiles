resource "incus_instance" "windows" {
  name = "windows"
  type = "virtual-machine"
  # Bootstrap once with maintain windows image --import-to ostrich-mtls.
  # Keep the installed Windows disk independent of future image rebuilds.
  image = "windows-initial"
  profiles = [
    incus_profile.seat.name,
    incus_profile.streaming.name,
    incus_profile.audio.name,
  ]
  running = false

  config = {
    "limits.cpu"    = "12"
    "limits.memory" = "16GiB"
    # NixOS is the default owner of the shared GPU and peripherals.
    "boot.autostart"      = "false"
    "security.secureboot" = "true"
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
    name = "agent"
    type = "disk"
    properties = {
      source = "agent:config"
    }
  }

  device {
    name       = "tpm"
    type       = "tpm"
    properties = {}
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [image, running]
  }
}
