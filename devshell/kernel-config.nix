{ pkgs, ... }:
let
  updateConfigNix = pkgs.writeShellApplication {
    name = "update-config-nix";
    text = ''
      echo "updating config.nix..."
      pushd "$PRJ_ROOT"
      nom build .#nixosConfigurations.enchilada.config.passthru.kernel.conf2nix --builders @/etc/nix-build-machines/hydra-builder/machines --out-link result
      cp ./result nixos/profiles/boot/kernel/sdm845-mainline/_config.nix
      popd
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        package = updateConfigNix;
        category = "data";
      }
    ];
  };
}
