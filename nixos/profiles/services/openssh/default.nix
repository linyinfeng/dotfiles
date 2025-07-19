{
  config,
  lib,
  ...
}:
let
  aliveInterval = "15";
  aliveCountMax = "4";
  knownHosts = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (host: hostData: [
        (lib.nameValuePair "${host}-ed25519" {
          hostNames = [
            host
            "${host}.li7g.com"
            "${host}.ts.li7g.com"
            "${host}.dn42.li7g.com"
          ];
          publicKey = hostData.ssh_host_ed25519_key_pub;
        })
        (lib.nameValuePair "${host}-rsa" {
          hostNames = [
            host
            "${host}.li7g.com"
            "${host}.ts.li7g.com"
            "${host}.dn42.li7g.com"
          ];
          publicKey = hostData.ssh_host_rsa_key_pub;
        })
      ]) config.networking.hostsData.indexedHosts
    )
  );
in
{
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
        inherit (config.sops.secrets."ssh_host_rsa_key") path;
        type = "rsa";
      }
      {
        inherit (config.sops.secrets."ssh_host_ed25519_key") path;
        type = "ed25519";
      }
    ];
  };

  programs.ssh.knownHosts = knownHosts;

  programs.ssh = {
    extraConfig = ''
      ServerAliveInterval ${aliveInterval}
      ServerAliveCountMax ${aliveCountMax}
    ''
    + lib.concatMapStringsSep "\n" (h: ''
      Host ${h}
        HostName ${h}.dn42.li7g.com
        Port ${toString config.ports.ssh}
      Host ${h}.dn42
        HostName ${h}.dn42.li7g.com
        Port ${toString config.ports.ssh}
      Host ${h}.ts
        HostName ${h}.ts.li7g.com
        Port ${toString config.ports.ssh}
    '') (lib.attrNames config.networking.hostsData.indexedHosts);
  };

  sops.secrets."ssh_host_rsa_key" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    restartUnits = [ "sshd.service" ];
  };
  sops.secrets."ssh_host_ed25519_key" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    restartUnits = [ "sshd.service" ];
  };

  environment.global-persistence.user.directories = [ ".ssh" ];
}
