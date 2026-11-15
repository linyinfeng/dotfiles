moved {
  from = incus_profile.gpu
  to   = incus_profile.seat
}

resource "incus_profile" "seat" {
  name        = "seat"
  description = "RTX 4060 and local input devices"

  device {
    name = "gpu"
    type = "gpu"
    properties = {
      gputype = "physical"
      pci     = "0000:01:00.0"
    }
  }

  # 68EC-S keyboard connected through the KVM switch.
  device {
    name = "keyboard"
    type = "usb"
    properties = {
      vendorid  = "0483"
      productid = "5132"
    }
  }

  # ATK Mouse 8K Dongle connected through the KVM switch.
  device {
    name = "mouse"
    type = "usb"
    properties = {
      vendorid  = "373b"
      productid = "101b"
    }
  }
}

resource "incus_profile" "streaming" {
  name        = "streaming"
  description = "Camera and video capture devices"

  # HIK 2K Camera (including its microphone).
  device {
    name = "camera"
    type = "usb"
    properties = {
      vendorid  = "2bdf"
      productid = "028a"
    }
  }

  # AVerMedia Live Gamer EXTREME 3
  device {
    name = "capture"
    type = "usb"
    properties = {
      vendorid  = "07ca"
      productid = "3551"
    }
  }
}

resource "incus_profile" "audio" {
  name        = "audio"
  description = "Onboard audio, Scarlett Solo and Keystation MIDI keyboard"

  # Motherboard HD Audio controller, in its own IOMMU group.
  device {
    name = "onboard-audio"
    type = "pci"
    properties = {
      address = "0000:13:00.6"
    }
  }

  # Focusrite Scarlett Solo 4th Gen
  device {
    name = "usb-audio"
    type = "usb"
    properties = {
      vendorid  = "1235"
      productid = "8218"
    }
  }

  # M-Audio Keystation 61 MK3
  device {
    name = "midi"
    type = "usb"
    properties = {
      vendorid  = "0763"
      productid = "3109"
    }
  }
}
