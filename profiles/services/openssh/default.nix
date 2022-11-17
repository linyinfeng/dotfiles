{ self, lib, ... }:

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
    '' + lib.concatMapStringsSep "\n"
      (h: ''
        Host ${h}
          HostName ${h}.ts.li7g.com
        Host ${h}.zt
          HostName ${h}.zt.li7g.com
        Host ${h}.ts
          HostName ${h}.ts.li7g.com
      '')
      (lib.attrNames self.lib.data.hosts);
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
