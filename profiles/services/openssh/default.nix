{ ... }:

{
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;

  networking.firewall.allowedTCPPorts = [ 22 ];

  environment.global-persistence = {
    etcFiles = [
      # ssh daemon host keys
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    user.files = [
      ".ssh/authorized_keys"
      ".ssh/config"
      ".ssh/id_rsa"
      ".ssh/id_rsa.pub"
      ".ssh/known_hosts"
    ];
  };
}
