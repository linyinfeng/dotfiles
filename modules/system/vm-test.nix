{ config, lib, ... }:

let
  isVmTest = config.system.nixos.revision == "constant-nixos-revision";
in
{
  options.system.is-vm-test = lib.mkOption {
    type = lib.types.bool;
    default = isVmTest;
    readOnly = true;
    description = ''
      Wheather the configuration is built in a vm test environment.
    '';
  };

  config = lib.mkIf config.system.is-vm-test {
    # print more logs for debug
    systemd.services.debug-unfinished = {
      enable = true;
      script = ''
        while true; do
          systemctl list-units --failed
          systemctl list-jobs --full
          sleep 10
        done
      '';
      wantedBy = [ "default.target" ];
    };
  };
}
