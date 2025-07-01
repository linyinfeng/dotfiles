{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.boot.android.bootImg;
  inherit (config.mobile.system.android) bootimg;
  bootspecNamespace = "com.github.linyinfeng.dotfiles";
  bootImgInstall = pkgs.writeShellApplication {
    name = "boot-img-install";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      ${lib.optionalString cfg.verbose ''
        set -x
      ''}

      working_dir="$(mktemp --directory -t boot-img-install.XXXXXX)"
      pushd "$working_dir" >/dev/null

      boot_json="/nix/var/nix/profiles/system/boot.json"

      init="$(jq --raw-output '."org.nixos.bootspec.v1".init' "$boot_json")"
      cmdline="$(jq --raw-output '["'"init=$init"'"] + ."org.nixos.bootspec.v1".kernelParams | join(" ")' "$boot_json")"
      initrd="$(jq --raw-output '."org.nixos.bootspec.v1".initrd' "$boot_json")"
      kernel="$(jq --raw-output '."org.nixos.bootspec.v1".kernel' "$boot_json")"
      dtbs="$(jq --raw-output '."${bootspecNamespace}".dtbs' "$boot_json")"

      echo 'appending dtbs to kernel...'
      cp "$kernel" kernel
      while read -r dtb; do
        cat "$dtb" >>kernel
      done < <(find "$dtbs" -type f -name "*.dtb")

      echo 'making boot.img...' >&2
      mkbootimg \
        --kernel "$kernel" \
        ${lib.optionalString (bootimg.dt != null) "--dt ${bootimg.dt}"} \
        --ramdisk "$initrd" \
        --cmdline "$cmdline" \
        --base           ${bootimg.flash.offset_base} \
        --kernel_offset  ${bootimg.flash.offset_kernel} \
        --second_offset  ${bootimg.flash.offset_second} \
        --ramdisk_offset ${bootimg.flash.offset_ramdisk} \
        --tags_offset    ${bootimg.flash.offset_tags} \
        --pagesize       ${bootimg.flash.pagesize} \
        -o boot.img

      echo 'flashing boot.img image to ${cfg.device}...' >&2
      dd if=boot.img of="${cfg.device}" conv=fdatasync ${
        lib.optionalString (!cfg.verbose) "2>/dev/null"
      } >&2

      popd >/dev/null
      rm --recursive "$working_dir"
    '';
  };
in
{
  options.boot.android.bootImg = {
    device = lib.mkOption {
      type = with lib.types; str;
    };
    verbose = lib.mkEnableOption "verbose logging";
  };
  config = {
    boot.bootspec = {
      enable = true;
      extensions.${bootspecNamespace} = {
        dtbs = config.hardware.deviceTree.package;
      };
    };
    boot.loader.external = {
      enable = true;
      installHook = lib.getExe bootImgInstall;
    };
  };
}
