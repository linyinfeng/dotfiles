{ config, pkgs, ... }:
let
  disk = "${config.system.build.diskoImages}/main.qcow2";
  metadataYaml = (pkgs.formats.yaml { }).generate "metadata.yaml" {
    architecture = pkgs.stdenv.hostPlatform.parsed.cpu.name;
    creation_date = 1;
    properties = {
      os = config.system.nixos.distroId;
      release = config.system.nixos.codeName;
      description = "${config.system.nixos.distroName} ${config.system.nixos.label} (${config.networking.hostName}) ${pkgs.stdenv.hostPlatform.system}";
    };
  };
  metadata =
    pkgs.runCommand "ostrich-incus-metadata.tar.xz"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.xz
        ];
      }
      ''
        mkdir metadata
        cp ${metadataYaml} metadata/metadata.yaml
        tar --sort=name --mtime=@1 --owner=0 --group=0 --numeric-owner \
          -cJf "$out" -C metadata metadata.yaml
      '';
in
{
  # QEMU's G suffix uses GiB, matching the Incus root volume.
  disko.devices.disk.main.imageSize = "256G";
  disko.imageBuilder.imageFormat = "qcow2";
  disko.imageBuilder.extraRootModules = [ "btrfs" ];
  disko.memSize = 4096;

  system.build.incusImage = pkgs.linkFarm "ostrich-incus-image" [
    {
      name = "rootfs.qcow2";
      path = disk;
    }
    {
      name = "metadata.tar.xz";
      path = metadata;
    }
  ];
}
