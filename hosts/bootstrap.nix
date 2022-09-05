{ profiles, suites, ... }:
{
  imports = suites.core ++ [
    profiles.users.root # make sure to configure ssh keys
    profiles.users.nixos
  ];

  boot.loader.systemd-boot.enable = true;

  # will be overridden by the bootstrapIso instrumentation
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; };
}
