{ pkgs, ... }:
let
  updateData = pkgs.writeShellApplication {
    name = "update-data";
    text = ''
      echo "updating patches..."
      pushd "$PRJ_ROOT/patches" >/dev/null
      # currently nothing
      curl --location https://github.com/Alexays/Waybar/pull/3930.patch >waybar-3930.patch
      popd >/dev/null

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
        package = updateData;
        category = "data";
      }
    ];
  };
}
