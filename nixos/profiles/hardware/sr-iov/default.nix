{ config, pkgs, ... }:
{
  boot.kernelParams = [
    "intel_iommu=on"
    "i915.enable_guc=3"
    "i915.max_vfs=7"
  ];
  systemd.services.setup-sriov =
    let
      num = 1;
    in
    {
      script = ''
        set -e
        echo ${toString num} | tee /sys/devices/pci0000:00/0000:00:02.0/sriov_numvfs
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      requiredBy = [ "libvirtd.service" ];
      before = [ "libvirtd.service" ];
    };
  systemd.services.detach-sriov-devices = {
    script = ''
      set -e
      virsh nodedev-detach pci_0000_00_02_1
    '';
    path = with pkgs; [ libvirt ];
    serviceConfig = {
      Type = "oneshot";
    };
    requiredBy = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
    before = [ "libvirt-guests.service" ];
  };
  environment.systemPackages = with pkgs; [ looking-glass-client ];
  # https://looking-glass.io/docs/B6/module/#vm-host
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      (
        if (config.boot ? kernelModuleSigning && config.boot.kernelModuleSigning.enable) then
          (kvmfr.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              config.boot.kernelModuleSigning.signModule
            ];
            # signature will be stripped
            dontStrip = true;
            postBuild = (old.postBuild or "") + ''
              sign-module kvmfr.ko
            '';
          }))
        else
          kvmfr
      )
    ];
    kernelModules = [ "kvmfr" ];
    extraModprobeConfig = ''
      options kvmfr static_size_mb=64
    '';
  };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="kvmfr", GROUP="libvirtd", MODE="0660"
  '';
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    cgroup_device_acl = [
      "/dev/null", "/dev/full", "/dev/zero",
      "/dev/random", "/dev/urandom",
      "/dev/ptmx", "/dev/kvm",
      "/dev/kvmfr0"
    ]
  '';
}
