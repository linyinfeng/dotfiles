{ pkgs, lib, ... }:
{
  boot = {
    # https://github.com/intel/linux-intel-lts/tags
    # https://github.com/intel/mainline-tracking/tags
    kernelPackages =
      let
        source = pkgs.nur.repos.linyinfeng.sources.linux-intel-lts;
        intelVersion = source.version;
        version = lib.elemAt (lib.strings.match "lts-v([0-9\\.]+)-linux-([0-9]+T[0-9]+Z)" intelVersion) 0;
        major = lib.versions.major version;
        minor = lib.versions.minor version;
        linux_intel_fn =
          {
            fetchFromGitHub,
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
              src = source.src;
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
  # because kernel needs to be recompiled
  # enable module signing and lockdown by the way
  boot.kernelModuleSigning.enable = true;
  boot.kernelLockdown = true;
}
