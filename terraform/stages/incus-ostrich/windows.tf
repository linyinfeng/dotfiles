resource "incus_storage_volume" "windows_steam" {
  name         = "windows-steam"
  description  = "Steam library disk for the Windows VM"
  pool         = "local"
  content_type = "block"

  config = {
    size = "256GiB"
  }

  lifecycle {
    prevent_destroy = true
  }
}

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
    "limits.cpu"          = "12"
    "limits.memory"       = "16GiB"
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
    name = "steam"
    type = "disk"
    properties = {
      pool     = incus_storage_volume.windows_steam.pool
      source   = incus_storage_volume.windows_steam.name
      "io.bus" = "virtio-scsi"
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      name           = "eth0"
      network        = incus_network.incusbr0.name
      "ipv4.address" = local.vm_subnet.windows
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
    # Power and shared device profiles are switched manually after creation.
    ignore_changes = [image, profiles, running]
  }
}
