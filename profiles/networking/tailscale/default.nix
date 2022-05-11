{ config, lib, ... }:

let
  interfaceName = "tailscale0";
in
{
  services.tailscale = {
    enable = true;
    port = 41641;
    inherit interfaceName;
  };
  systemd.services.tailscale-setup = {
    script = ''
      if tailscale status; then
        echo "tailscale already up, skip"
      else
        echo "tailscale down, login using auth key"
        tailscale up --auth-key "file:${config.sops.secrets."tailscale".path}"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.services.tailscale.package ];
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.service" ];
  };
  sops.secrets."tailscale".sopsFile = config.sops.secretsDir + /infrastructure.yaml;
  # no need to open ports
  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];
  networking.firewall.checkReversePath = lib.mkForce "loose";
}
