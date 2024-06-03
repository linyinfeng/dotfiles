{ config, pkgs, ... }:
{
  system.build.initialRamdiskRoot = config.system.build.initialRamdisk.overrideAttrs (old: {
    name = "initrd-root";
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.cpio ];
    buildCommand = ''
      mkdir -p ./root/var/empty
      make-initrd-ng "$contentsPath" ./root
      (cd root && find . -exec touch -h -d '@1' '{}' +)
      pushd root
      for PREP in $prepend; do
        cpio --extract --make-directories --verbose <"$PREP"
      done
      popd
      cp --recursive root "$out"
    '';
  });
}
