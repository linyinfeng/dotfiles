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
