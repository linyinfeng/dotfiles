{ config, lib, ... }:

let
  defaultVoicePort = 9987;
  fileTransferPort = 30033;
  queryPort = 10011;
in

# network is not available in vm-test
lib.mkIf (!config.system.is-vm-test) {
  services.teamspeak3 = {
    enable = true;
    inherit defaultVoicePort fileTransferPort queryPort;
  };

  networking.firewall.allowedTCPPorts = [ queryPort fileTransferPort ];
  networking.firewall.allowedUDPPorts = [ defaultVoicePort ];
}
