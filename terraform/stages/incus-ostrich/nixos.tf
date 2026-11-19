resource "incus_instance" "nixos" {
  name = "nixos"
  type = "virtual-machine"
  # Manually import the initial image with this alias before the first apply.
  # Subsequent NixOS deployments update the guest in place.
  image    = "ostrich-initial"
  profiles = []
  # Keep creation stopped; subsequent power changes are operational actions.
  running = false

  config = {
    "limits.cpu"          = "12"
    "limits.memory"       = "8GiB"
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
      name           = "eth0"
      network        = incus_network.incusbr0.name
      "ipv4.address" = local.vm_subnet.nixos
    }
  }

  device {
    name       = "tpm"
    type       = "tpm"
    properties = {}
  }

  lifecycle {
    prevent_destroy = true
    # Power and shared device profiles are switched manually after creation.
    ignore_changes = [image, profiles, running]
  }
}
