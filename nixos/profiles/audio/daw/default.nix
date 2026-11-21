{ pkgs, ... }:
{
  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    alsa-scarlett-gui # Scarlett Solo 4th Gen control panel
    alsa-utils # amixer/alsactl/aconnect
  ];

  # 256 frames at 48 kHz is ~5.3 ms; allowed-rates is the Scarlett Solo 4th Gen's range.
  # Override PipeWire's built-in VM rule (cpu.vm.name = !null -> min-quantum = 1024)
  # so passthrough audio interfaces on VM workstations keep low-latency quantums.
  services.pipewire.extraConfig.pipewire."10-daw" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [
        44100
        48000
        88200
        96000
        176400
        192000
      ];
      "default.clock.quantum" = 256;
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 1024;
    };
    "context.properties.rules" = [
      {
        matches = [ { "cpu.vm.name" = "!null"; } ];
        actions.update-props = {
          "default.clock.min-quantum" = 32;
        };
      }
    ];
  };

  # keep the interface powered: the default 5 s idle suspend pops on the next note
  services.pipewire.wireplumber.extraConfig."51-focusrite" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_(input|output)\\.usb-Focusrite.*"; }
        ];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }
    ];
  };

  # system76-scheduler resets matched processes to SCHED_OTHER (and demotes
  # user systemd services like carla.service to nice=9 / io=idle); exempt
  # the real-time audio graph so PipeWire module-rt keeps SCHED_RR.
  services.system76-scheduler.exceptions = [
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "carla"
    "reaper"
    ''include name="*reaper*"''
    ''include cgroup="/user.slice/*/app.slice/carla.service"''
    ''include cgroup="/user.slice/*/session.slice/pipewire.service"''
    ''include cgroup="/user.slice/*/session.slice/pipewire-pulse.service"''
    ''include cgroup="/user.slice/*/session.slice/wireplumber.service"''
  ];

  # rtkit covers PipeWire; REAPER's own ALSA backend asks for SCHED_FIFO itself
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "95";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "nice";
      type = "-";
      value = "-20";
    }
  ];
}
