{
  suites,
  profiles,
  lib,
  ...
}:
{
  imports =
    suites.server
    ++ (with profiles; [
      # TODO
    ])
    ++ [ ./nixos-riscv-tweaks.nix ];

  config = lib.mkMerge [
    {
      # TODO
    }

    # stateVersion
    { system.stateVersion = "23.11"; }
  ];
}
