{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  tag = "sdm845-6.16.7-r0";
  hash = "sha256-XYlXuzapuesiTpvquuz0b6yPyAqEdK9lMdglST+EZhk=";
  version = "6.16.7";
  inherit (lib.kernel) yes;
  structuredExtraConfig = {
    EROFS_FS = yes;
  };
  patchedSrc = pkgs.stdenv.mkDerivation {
    name = "linux-sdm845-patched-src";
    inherit version;
    src = pkgs.fetchFromGitLab {
      owner = "sdm845-mainline";
      repo = "linux";
      rev = tag;
      inherit hash;
    };
    postPatch = ''
      cp "${inputs.pmaports}/device/community/linux-postmarketos-qcom-sdm845/config-postmarketos-qcom-sdm845.aarch64"  arch/arm64/configs/pmos_sdm845_defconfig
    '';
    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir --parents $out
      cp --recursive . $out
      runHook postInstall
    '';
  };
in
{
  boot = {
    kernelPackages =
      let
        linux_sdm845 = pkgs.buildLinux {
          inherit version;
          modDirVersion = "${lib.versions.pad 3 version}-sdm845";
          extraMeta.branch = lib.versions.majorMinor version;
          src = patchedSrc;
          defconfig = "pmos_sdm845_defconfig";
          autoModules = false;
          enableCommonConfig = false;
          inherit structuredExtraConfig;
          kernelPatches = with pkgs.kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
        };
      in
      lib.recurseIntoAttrs (pkgs.linuxPackagesFor linux_sdm845);
  };
}
