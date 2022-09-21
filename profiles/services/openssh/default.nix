{ ... }:

let
  aliveInterval = "15";
  aliveCountMax = "4";
in
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    extraConfig = ''
      ClientAliveInterval ${aliveInterval}
      ClientAliveCountMax ${aliveCountMax}
    '';
  };

  programs.ssh = {
    extraConfig = ''
      ServerAliveInterval ${aliveInterval}
      ServerAliveCountMax ${aliveCountMax}
    '';
  };

  environment.global-persistence = {
    files = [
      # ssh daemon host keys
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    user.directories = [
      ".ssh"
    ];
  };
}
