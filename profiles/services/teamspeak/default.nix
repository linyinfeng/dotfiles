{ config, lib, ... }:

let
  defaultVoicePort = config.ports.teamspeak-voice;
  fileTransferPort = config.ports.teamspeak-file-transfer;
  queryPort = config.ports.teamspeak-query;
in

{
  services.teamspeak3 = {
    enable = true;
    inherit defaultVoicePort fileTransferPort queryPort;
  };

  networking.firewall.allowedTCPPorts = [ queryPort fileTransferPort ];
  networking.firewall.allowedUDPPorts = [ defaultVoicePort ];
}
