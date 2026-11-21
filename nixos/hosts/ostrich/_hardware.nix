{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  virtualisation.incus.agent.enable = true;

  # The RTX 4060 is passed through from IncusOS while this VM is running.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    branch = "latest";
    modesetting.enable = true;
    nvidiaSettings = true;
  };

  home-manager.users.yinfeng.services.kanshi.settings =
    let
      virtual = "Virtual-1";
    in
    [
      {
        profile = {
          name = "physical";
          outputs = [
            {
              criteria = virtual;
              status = "disable";
            }
            {
              # The remaining output is the monitor connected to the RTX 4060.
              criteria = "*";
              status = "enable";
              position = "0,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "virtual";
          outputs = [
            {
              criteria = virtual;
              status = "enable";
              position = "0,0";
            }
          ];
        };
      }
    ];

  # TODO: Remove this workaround once greetd's `greeter` system user no longer
  # starts its own stateless PipeWire/WirePlumber instance (upstream PipeWire
  # user units only check `ConditionUser=!root` instead of
  # `ConditionUser=!@system`). On boot, `greeter`'s WirePlumber cannot access
  # `/var/empty/.local/state/wireplumber` while holding seat0 ACLs on
  # `/dev/snd/controlC1`, resetting the ALC897 Line In hardware mixer to 100%
  # (+60 dB) after `yinfeng`'s lingering WirePlumber already restored 10%
  # (0.00 dB) from `default-routes`.
  home-manager.users.yinfeng.systemd.user =
    let
      clampLineIn = pkgs.writeShellApplication {
        name = "clamp-ostrich-line-in-volume";
        runtimeInputs = with pkgs; [
          gawk
          jq
          pipewire
          wireplumber
        ];
        text = ''
          node_id=$(
            pw-dump | jq -r '
              [.[]
               | select(.type == "PipeWire:Interface:Node"
                   and .info.props."node.name" == "alsa_input.pci-0000_07_00.0.analog-stereo")][0].id // empty
            '
          )
          if [ -z "$node_id" ]; then
            exit 0
          fi

          vol=$(wpctl get-volume "$node_id" | awk '{ print $2 }')
          if [ -z "$vol" ]; then
            exit 0
          fi

          if awk -v v="$vol" 'BEGIN { exit !(v > 0.1001) }'; then
            wpctl set-volume "$node_id" 0.10
          fi
        '';
      };
    in
    {
      services.clamp-line-in-volume = {
        Unit = {
          Description = "Clamp ostrich onboard Line In volume to 10% (0.00 dB)";
          After = [
            "pipewire.service"
            "wireplumber.service"
          ];
          Requires = [ "pipewire.service" ];
          Wants = [ "wireplumber.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe clampLineIn;
        };
      };
      timers.clamp-line-in-volume = {
        Unit = {
          Description = "Periodically clamp ostrich onboard Line In volume to 10%";
        };
        Timer = {
          OnActiveSec = "30s";
          OnUnitActiveSec = "1min";
          AccuracySec = "5s";
          Unit = "clamp-line-in-volume.service";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
    vulkan-tools
    libva-utils
  ];

  # Ada is the only GPU here, while the default build compiles kernels for
  # nine architectures
  services.llama-cpp.package = pkgs.llama-cpp-cuda.overrideAttrs (old: {
    cmakeFlags =
      lib.filter (flag: !(lib.hasPrefix "-DCMAKE_CUDA_ARCHITECTURES" flag)) old.cmakeFlags
      ++ [ "-DCMAKE_CUDA_ARCHITECTURES=89" ];
  });
}
