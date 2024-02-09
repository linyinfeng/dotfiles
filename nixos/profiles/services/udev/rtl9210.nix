{...}: {
  services.udev.extraRules = ''
    ACTION=="add|change", ATTRS{idVendor}=="31db", ATTRS{idProduct}=="9210", SUBSYSTEM=="scsi_disk", ATTR{provisioning_mode}="unmap"
  '';
}
