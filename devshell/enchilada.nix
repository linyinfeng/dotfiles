{ pkgs, ... }:
let
  flashEnchilada = pkgs.writeShellApplication {
    name = "flash-enchilada";
    runtimeInputs = with pkgs; [
      android-tools
    ];
    text = ''
      cd "$PRJ_ROOT"

      function nom_hydra {
        nom build --builders @/etc/nix-build-machines/hydra-builder/machines "$@"
      }

      nom_hydra .#nixosConfigurations.enchilada.config.system.build.toplevel
      nom build .#nixosConfigurations.enchilada.config.system.build.bootImage --out-link result-boot-img
      nom build .#nixosConfigurations.enchilada.config.system.build.rootfsImage --impure --out-link result-rootfs-img

      # reboot first to workaround bootloader bug
      fastboot reboot bootloader
      fastboot set_active a
      fastboot reboot bootloader
      fastboot flash boot ./result-boot-img
      fastboot reboot bootloader
      fastboot flash userdata ./result-rootfs-img/rootfs.img
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        package = flashEnchilada;
        category = "android";
      }
    ];
  };
}
