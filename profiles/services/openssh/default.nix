{ ... }:

{
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  networking.firewall.allowedTCPPorts = [ 22 ];

  environment.global-persistence.etcFiles = [
    # ssh daemon host keys
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
  ];
}
