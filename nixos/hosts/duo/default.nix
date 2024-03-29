{
  suites,
  profiles,
  lib,
  ...
}:
{
  imports =
    suites.embeddedServer
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
