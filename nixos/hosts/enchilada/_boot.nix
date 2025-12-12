{
  inputs,
  config,
  pkgs,
  lib,
  profiles,
  ...
}:

let
  inherit (config.system.build) toplevel;
  inherit (config.mobile) device;
  inherit (config.mobile.system.android) bootimg;

  extraInitrdFirmware = [ "/lib/firmware/qcom/sdm845/oneplus6/a630_zap.mbn" ];
  modulesClosure = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
    kernel = config.system.modulesTree;
    inherit (config.hardware) firmware;
    allowMissing = false;
  };
  modulesClosureExtended = pkgs.runCommand "${modulesClosure.name}-extended" { } ''
    mkdir $out
    cp --verbose --recursive --no-preserve=mode "${modulesClosure}/lib" "$out/lib"
    # extra modules
    ${lib.concatMapStringsSep "\n" (f: ''
      mkdir --parents "$out$(dirname "${f}")"
      cp --verbose --no-preserve=mode {"${config.hardware.firmware}","$out"}"${f}"
    '') extraInitrdFirmware}
  '';

  # TODO switch UEFI and ZBOOT with vmlinuz.efi
  imageGz = pkgs.runCommand "Image.gz" { nativeBuildInputs = with pkgs; [ gzip ]; } ''
    mkdir $out
    gzip --stdout "${config.boot.kernelPackages.kernel}/Image" >"$out/Image.gz"
  '';
  kernelForBootImg = pkgs.symlinkJoin {
    name = "kernel-for-bootimg";
    paths = [
      config.boot.kernelPackages.kernel
      imageGz
    ];
  };
  hideSplash = pkgs.writeShellApplication {
    name = "hide-splash";
    runtimeInputs = with pkgs; [
      plymouth
    ];
    text = ''
      plymouth hide-splash
    '';
  };
in
{
  boot.consoleLogLevel = 6;
  imports = with profiles; [
    boot.android.boot-img
  ];
  nixpkgs.overlays = [
    (_final: _prev: {
      # don't compress firmware to speed up loading
      compressFirmwareZstd = lib.id;
    })
  ];

  boot.initrd.systemd.services.initrd-nixos-activation = {
    serviceConfig = {
      StandardOutput = "journal+console";
    };
  };

  boot.initrd.systemd.contents = {
    "/lib".source = lib.mkForce "${modulesClosureExtended}/lib";
  };
  boot.initrd.systemd.services.plymouth-hide-splash = {
    script = lib.getExe hideSplash;
    after = [ "plymouth-start.service" ];
    wantedBy = [ "plymouth-start.service" ];
  };
  mobile.boot.stage-1.enable = lib.mkForce false;
  boot.initrd.systemd.managerEnvironment = {
    # bootloader will append extra android kernel cmdline to our cmdline
    # we just want systemd to use our cmdline
    SYSTEMD_PROC_CMDLINE = lib.concatStringsSep " " (
      config.boot.kernelParams
      ++ [
        # initrd can not contain toplevel so that we can not use "init=${toplevel}/init" here
        # evaluation will be infinite recursion since initrd will be included in toplevel
        "init=/nix/var/nix/profiles/system/init"
      ]
    );
  };
  system.build.bootImage =
    pkgs.callPackage "${inputs.mobile-nixos}/modules/system-types/android/bootimg.nix"
      {
        name = "mobile-nixos-${device.name}-${bootimg.name}";
        inherit bootimg;
        cmdline = lib.concatStringsSep " " (
          config.boot.kernelParams
          ++ [
            # provide closure information to initrd-nixos-activation.service
            "init=${toplevel}/init"
          ]
        );
        kernel = "${kernelForBootImg}/Image.gz";
        initrd = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
        inherit (config.mobile.system.android) appendDTB;
      };
  mobile.outputs.android.android-bootimg = lib.mkForce config.system.build.bootImage;
  # impure
  # populate sops-nix key from my home directory
  mobile.generatedFilesystems.rootfs = lib.mkDefault {
    populateCommands = lib.mkAfter ''
      echo "Copying './var/lib/sops-nix/key'..."
      mkdir --verbose --mode=755 --parents ./var/lib
      mkdir --verbose --mode=700 ./var/lib/sops-nix
      cp --verbose "${/home/yinfeng/Data/Documents/enchilada/key.txt}" ./var/lib/sops-nix/key
      chmod --verbose 600 ./var/lib/sops-nix/key
      echo "Done copying './var/lib/sops-nix/key'..."
    '';
  };
  system.build.rootfsImage = config.mobile.generatedFilesystems.rootfs.output;
  mobile.system.android.boot_partition_destination = "boot_a";
  mobile.system.android.system_partition_destination = "userdata";
  system.build.flashableZip = config.mobile.outputs.android.android-flashable-zip;
  system.build.toplevelClosureInfo = pkgs.closureInfo { rootPaths = config.system.build.toplevel; };
}
