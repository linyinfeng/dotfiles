{ config, lib, ... }:

let
  cfg = config.system.perlless;
in
{
  options = {
    system.perlless.enable = lib.mkOption {
      type = lib.types.bool;
      default = lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.6";
      defaultText = ''lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.6"'';
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        system.etc.overlay.enable = lib.mkDefault true;
        environment.etc."NIXOS".text = "";
        services.userborn = {
          enable = true;
          passwordFilesLocation = "/var/lib/userborn";
        };
      }
    ]
  );
}
