{ config, pkgs, ... }:
let
  originalPackage = config.boot.kernelPackages.nvidiaPackages.stable;
  package =
    if (config.boot ? kernelModuleSigning && config.boot.kernelModuleSigning.enable) then
      originalPackage
      // {
        open = originalPackage.open.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            config.boot.kernelModuleSigning.signModule
          ];
          # signature will be stripped
          dontStrip = true;
          postBuild =
            (old.postBuild or "")
            + ''
              for module in kernel-open/*.ko; do
                sign-module "$module"
              done
            '';
        });
      }
    else
      originalPackage;
  # switcherooctl is broken
  # Traceback (most recent call last):
  # File "/nix/store/zv2w5xrj6m4jx9yi3v37p5grcpl3hxp4-switcheroo-control-2.6/bin/.switcherooctl-wrapped", line 4, in <module>
  #   from gi.repository import Gio, GLib
  # File "/nix/store/x58gx2c52d8h0a54zylrrx85qjpjzyjk-python3.12-pygobject-3.48.2/lib/python3.12/site-packages/gi/importer.py", line 133, in create_module
  #   raise ImportError('cannot import name %s, '
  # ImportError: cannot import name Gio, introspection typelib not found
  primeRun = pkgs.writeShellApplication {
    name = "prime-run";
    text = ''
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '';
  };
  envVars = {
    # currently nothing
  };
in
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    inherit package;
  };
  services.switcherooControl.enable = true;
  environment.systemPackages = with pkgs; [
    primeRun
    intel-gpu-tools
    nvitop
    nvtopPackages.full
    vulkan-tools
    cudatoolkit
  ];
  systemd.services.display-manager.environment = envVars;
  environment.sessionVariables = envVars;
}
