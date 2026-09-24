{ lib, ... }:
{
  world.suites.base.enable = lib.mkDefault true;
  world.suites.network.enable = lib.mkDefault true;
  world.suites.backup.enable = lib.mkDefault true;
  world.suites.monitoring.enable = lib.mkDefault true;

  world.profiles.system.types.server.enable = lib.mkDefault true;
  world.profiles.services.auto-upgrade.enable = lib.mkDefault true;
  world.profiles.services.bpftune.enable = lib.mkDefault true;
  world.profiles.services.iperf3.enable = lib.mkDefault true;
  world.profiles.programs.terminal-multiplexing.enable = lib.mkDefault true;
  world.profiles.networking.bbr.enable = lib.mkDefault true;
}
