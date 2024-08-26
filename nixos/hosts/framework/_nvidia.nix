{ config, ... }:
let
  originalPackage = config.boot.kernelPackages.nvidiaPackages.stable;
  package = originalPackage // {
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
}
