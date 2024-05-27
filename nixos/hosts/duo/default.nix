{
  suites,
  lib,
  pkgs,
  ...
}:
{
  imports = suites.embeddedServer ++ [ ./nixos-riscv-tweaks.nix ];

  config = lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        dnsutils
        iperf3
        htop
      ];

      systemd.network.networks."50-end0" = {
        matchConfig = {
          Name = "end0";
        };
        DHCP = "yes";
      };

      system.nproc = 1;
      documentation.nixos.enable = false;
    }

    # stateVersion
    { system.stateVersion = "24.05"; }
  ];
}
