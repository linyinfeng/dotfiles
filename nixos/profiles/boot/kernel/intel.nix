{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.boot.kernel.intel;
in
{
  options.boot.kernel.intel.type = lib.mkOption {
    type = lib.types.enum [
      "lts"
      "mainline-tracking"
    ];
    default = "lts";
  };
  config.boot = {
    # https://github.com/intel/linux-intel-lts/tags
    # https://github.com/intel/mainline-tracking/tags
    kernelPackages =
      let
        source = pkgs.nur.repos.linyinfeng.sources."linux-intel-${cfg.type}";
        intelVersion = source.version;
        version = lib.elemAt (lib.strings.match "${cfg.type}-v([0-9\\.]+)-linux-([0-9]+T[0-9]+Z)" intelVersion) 0;
        major = lib.versions.major version;
        minor = lib.versions.minor version;
        linux_intel_fn =
          {
            buildLinux,
            ccacheStdenv,
            lib,
            ...
          }@args:
          buildLinux (
            args
            // {
              # build with ccacheStdenv
              stdenv = ccacheStdenv;
              inherit version;
              modDirVersion = lib.versions.pad 3 version;
              extraMeta.branch = lib.versions.majorMinor version;
              inherit (source) src;
            }
            // (args.argsOverride or { })
          );
        linux_intel = pkgs.callPackage linux_intel_fn {
          kernelPatches = lib.filter (
            p: !(lib.elem p.name [ ])
          ) pkgs."linuxPackages_${major}_${minor}".kernel.kernelPatches;
        };
      in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_intel);
    kernelPatches = [
      # currently nothing
    ];
  };
}
