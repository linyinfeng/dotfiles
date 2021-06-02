{ anboxModulesPath, ... }:

{
  imports = [ "${anboxModulesPath}/virtualisation/anbox.nix" ];
  disabledModules = [ "virtualisation/anbox.nix" ];
  virtualisation.anbox.enable = true;
  # virtualisation.anbox.enable = false; # TODO: broken
  boot.kernelPatches = [{
    name = "anbox-patch";
    patch = null;
    extraConfig =
      ''
        ASHMEM y
        ANDROID y
        ANDROID_BINDER_IPC y
        ANDROID_BINDERFS y
        ANDROID_BINDER_DEVICES binder,hwbinder,vndbinder
      '';
  }];
}
