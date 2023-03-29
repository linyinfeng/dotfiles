{
  config,
  lib,
  ...
}: let
  aliveInterval = "15";
  aliveCountMax = "4";
  knownHosts = lib.listToAttrs (lib.flatten (lib.mapAttrsToList
    (host: hostData: [
      (lib.nameValuePair "${host}-ed25519" {
        hostNames = [host "${host}.li7g.com" "${host}.ts.li7g.com" "${host}.zt.li7g.com"];
        publicKey = hostData.ssh_host_ed25519_key_pub;
      })
      (lib.nameValuePair "${host}-rsa" {
        hostNames = [host "${host}.li7g.com" "${host}.ts.li7g.com" "${host}.zt.li7g.com"];
        publicKey = hostData.ssh_host_rsa_key_pub;
      })
    ])
    config.lib.self.data.hosts));
in {
  services.openssh = {
    enable = true;
    ports = [ config.ports.ssh ];
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

  programs.ssh.knownHosts = knownHosts;

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
          Port ${toString config.ports.ssh}
        Host ${h}.zt
          HostName ${h}.zt.li7g.com
          Port ${toString config.ports.ssh}
        Host ${h}.ts
          HostName ${h}.ts.li7g.com
          Port ${toString config.ports.ssh}
      '')
      (lib.attrNames config.lib.self.data.hosts);
  };

  sops.secrets."ssh_host_rsa_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["sshd.service"];
  };
  sops.secrets."ssh_host_ed25519_key" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["sshd.service"];
  };

  environment.global-persistence.user.directories = [
    ".ssh"
  ];
}
