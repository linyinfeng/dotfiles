{ pkgs, config, options, suites, profiles, lib, modulesPath, ... }:

{
  imports =
    suites.server ++
    (with profiles; [
    ]) ++ [
      (modulesPath + "/virtualisation/amazon-image.nix")
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      ec2 = {
        efi = false;
        hvm = true;
      };

      fileSystems."/" = lib.mkForce {
        device = "/dev/nvme0n1p1";
        fsType = "xfs";
      };
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens5.useDHCP = true;
      };
    }
  ];
}
