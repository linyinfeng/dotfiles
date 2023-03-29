{
  config,
  lib,
  ...
}: let
  aliveInterval = "15";
  aliveCountMax = "4";
in {
  services.openssh = {
    enable = true;
    openFirewall = true;
    extraConfig = ''
      ClientAliveInterval ${aliveInterval}
      ClientAliveCountMax ${aliveCountMax}
    '';
    hostKeys = [
      {
        bits = 4096;
        path = config.sops.secrets."ssh_host_rsa_key".path;
        type = "rsa";
      }
      {
        path = config.sops.secrets."ssh_host_ed25519_key".path;
        type = "ed25519";
      }
    ];
  };

  programs.ssh = {
    extraConfig =
      ''
        ServerAliveInterval ${aliveInterval}
        ServerAliveCountMax ${aliveCountMax}
      ''
      + lib.concatMapStringsSep "\n"
      (h: ''
        Host ${h}
          HostName ${h}.ts.li7g.com
        Host ${h}.zt
          HostName ${h}.zt.li7g.com
        Host ${h}.ts
          HostName ${h}.ts.li7g.com
      '')
      (lib.attrNames config.lib.self.data.hosts);
  };

  sops.secrets."ssh_host_rsa_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = [ "sshd.service" ];
  };
  sops.secrets."ssh_host_ed25519_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = [ "sshd.service" ];
  };

  environment.global-persistence = {
    user.directories = [
      ".ssh"
    ];
  };
}
