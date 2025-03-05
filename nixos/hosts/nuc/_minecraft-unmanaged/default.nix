{ config, pkgs, ... }:

let
  port = config.ports.minecraft;
  voicePort = config.ports.minecraft-voice; # also port for voice (udp)
  rconPort = config.ports.minecraft-rcon;
  mapPort = config.ports.minecraft-map;

  readme = pkgs.writeText "minecraft-unmanaged-readme" ''
    Public address:
    mc.li7g.com

    Ports exposed:
    TCP (minecraft): ${toString port}
    TCP (RCON): ${toString rconPort}
    UDP (voice): ${toString voicePort}

    Reverse proxied:
    HTTP: ${toString mapPort} (public: https://mc.li7g.com:8443)
  '';
in
{
  imports = [ ./backup.nix ];
  users.users.minecraft = {
    isNormalUser = true;
    home = "/var/lib/minecraft";
    group = "minecraft";
    shell = pkgs.fish;
    openssh.authorizedKeys = {
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2gehgxcJS9X3446pXsLkhPQQnCfeUS1yWC5mHc9/qC" ];
      inherit (config.users.users.root.openssh.authorizedKeys) keyFiles;
    };
  };
  users.groups.minecraft = { };
  nix.settings.allowed-users = [ "minecraft" ];

  systemd.tmpfiles.settings."90-minecraft-unmanaged" = {
    "${config.users.users.minecraft.home}" = {
      "v" = {
        user = "minecraft";
        group = "minecraft";
        mode = "700";
      };
    };
    "${config.users.users.minecraft.home}/README" = {
      "L+" = {
        user = "minecraft";
        group = "minecraft";
        argument = "${readme}";
      };
    };
  };

  services.nginx.virtualHosts."mc.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString mapPort}";
  };

  networking.firewall.allowedTCPPorts = [
    port
    rconPort
  ];
  networking.firewall.allowedUDPPorts = [ voicePort ];
}
