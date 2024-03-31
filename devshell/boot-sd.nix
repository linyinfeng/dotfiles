{ pkgs, ... }:
let
  updateBootSd = pkgs.writeShellApplication {
    name = "update-boot-sd";
    text = ''
      name="$1"
      shift

      bootsd=$(nix build "$PRJ_ROOT"#nixosConfigurations."$name".config.system.build.bootsd --no-link --print-out-paths)
      sha1sum "$bootsd"
      ssh "$@" '
        dd of=/firmware/boot.sd
        sha1sum /firmware/boot.sd
      ' <"$bootsd"
      sync
    '';
  };
in
{
  devshells.default = {
    commands = [
      {
        package = updateBootSd;
        category = "embedded";
      }
    ];
  };
}
