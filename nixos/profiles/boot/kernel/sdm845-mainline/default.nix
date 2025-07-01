{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  tag = "sdm845-6.16-rc2-4";
  hash = "sha256-Nu7BwSl40Ytm7nCzyctNed7nqwq7NcVVxHLF3KFMKC4=";
  version = lib.elemAt (lib.strings.match "sdm845-([0-9\\.]+(-rc[0-9]+)?)(-[a-zA-Z0-9\\-]+)?" tag) 0;
  major = lib.versions.major version;
  minor = lib.versions.minor version;
  inherit (lib.kernel) yes module;
  structuredExtraConfig =
    inputs.kukui-nixos.lib.adjustStandaloneConfig (import ./_config.nix { inherit lib; })
    // {
      # for envfs
      EROFS_FS = yes;
      NET_9P = module;
      CONFIG_NET_9P_VIRTIO = module;
      "9P_FS" = module;
      # other
      RUST = yes;
    };
in
{
  #
  passthru.kernel = {
    conf2nix = inputs.conf2nix.lib.conf2nix {
      configFile = "${inputs.pmaports}/device/community/linux-postmarketos-qcom-sdm845/config-postmarketos-qcom-sdm845.aarch64";
      inherit (config.boot.kernelPackages) kernel;
      preset = "standalone";
    };
  };
  boot = {
    kernelPackages =
      let
        linux_sdm845_fn =
          {
            buildLinux,
            lib,
            ...
          }@args:
          buildLinux (
            args
            // {
              inherit version;
              modDirVersion = "${lib.versions.pad 3 version}-sdm845";
              extraMeta.branch = lib.versions.majorMinor version;
              src = pkgs.fetchFromGitLab {
                owner = "sdm845-mainline";
                repo = "linux";
                rev = tag;
                inherit hash;
              };
              defconfig = "defconfig sdm845.config";
              enableCommonConfig = false;
              autoModules = false;
              inherit structuredExtraConfig;

              # ../configs/config.nix should fully explained the platform
              # clear hostPlatform.linux-kernel.extraConfig
              stdenv =
                let
                  originalPlatform = pkgs.stdenv.hostPlatform;
                  hostPlatform =
                    assert pkgs.stdenv.hostPlatform.isAarch64;
                    originalPlatform
                    // {
                      linux-kernel = originalPlatform.linux-kernel // {
                        extraConfig = "";
                      };
                    };
                in
                pkgs.stdenv // { inherit hostPlatform; };
            }
            // (args.argsOverride or { })
          );
        linux_sdm845' = pkgs.callPackage linux_sdm845_fn {
          kernelPatches = lib.filter (p: !(lib.elem p.name [ ])) (
            pkgs."linuxPackages_${major}_${minor}".kernel.kernelPatches or [ ]
          );
        };
        linux_sdm845 = linux_sdm845'.overrideAttrs (_old: {
        });
      in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_sdm845);
    kernelPatches = [
      # currently nothing
    ];
  };
}
