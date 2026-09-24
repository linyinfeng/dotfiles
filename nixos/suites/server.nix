{ ... }:
{
  world = {
    profiles = {
      networking.bbr.enable = true;
      programs.terminal-multiplexing.enable = true;
      services = {
        auto-upgrade.enable = true;
        bpftune.enable = true;
        iperf3.enable = true;
      };
      system.types.server.enable = true;
    };
    suites = {
      backup.enable = true;
      base.enable = true;
      monitoring.enable = true;
      network.enable = true;
    };
  };
}
