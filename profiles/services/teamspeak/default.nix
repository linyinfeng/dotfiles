{ config, lib, ... }:

let
  defaultVoicePort = 9987;
  fileTransferPort = 30033;
  queryPort = 10011;
in

{
  services.teamspeak3 = {
    enable = true;
    inherit defaultVoicePort fileTransferPort queryPort;
  };

  networking.firewall.allowedTCPPorts = [ queryPort fileTransferPort ];
  networking.firewall.allowedUDPPorts = [ defaultVoicePort ];
}
