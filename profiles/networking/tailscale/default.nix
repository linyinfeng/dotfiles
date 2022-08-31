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
  # don't auto start tailscaled if
  # - system is a workstation (easy reachable machines)
  # - zerotier is on
  systemd.services.tailscaled.wantedBy =
    lib.mkIf
      (lib.elem "workstation" config.system.types &&
        config.services.zerotierone.enable)
      (lib.mkForce [ ]);
  systemd.services.tailscale-setup = {
    script = ''
      sleep 10

      if tailscale status; then
        echo "tailscale already up, skip"
      else
        echo "tailscale down, login using auth key"
        tailscale up --auth-key "file:${config.sops.secrets."tailscale_tailnet_key".path}"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.services.tailscale.package ];
    after = [ "tailscaled.service" ];
    requiredBy = [ "tailscaled.service" ];
  };
  sops.secrets."tailscale_tailnet_key" = {
    sopsFile = config.sops.secretsDir + /terraform/infrastructure.yaml;
    restartUnits = [ "tailscale-setup.service" ];
  };
  # no need to open ports
  networking.firewall.allowedUDPPorts = [
    config.services.tailscale.port
  ];
  networking.firewall.checkReversePath = lib.mkForce "loose";
  networking.networkmanager.unmanaged = [ interfaceName ];
}
