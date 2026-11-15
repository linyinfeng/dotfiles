{
  config,
  lib,
  ...
}:
let
  servers = {
    ostrich = {
      addresses = [
        "https://192.168.3.6:8443"
        "https://ostrich-incus.bunny-mountain.ts.net:8443"
      ];
      serverCertificate = config.lib.self.data.acme_li7g_com_certificate_pem;
      noProxy = [ "ostrich-incus.bunny-mountain.ts.net" ];
    };
  };
  certificate = config.sops.secrets.incus_client_cert_chain_pem.path;
  privateKey = config.sops.secrets.incus_client_private_key_pem.path;
  remotes = lib.concatMapAttrs (
    name: server:
    let
      remote = {
        addr = lib.concatStringsSep "," server.addresses;
        protocol = "incus";
        public = false;
      };
    in
    {
      ${name} = remote // {
        auth_type = "oidc";
      };
      "${name}-mtls" = remote // {
        auth_type = "tls";
      };
    }
  ) servers;
  serverCertificates = lib.concatMapAttrs (name: server: {
    "incus/servercerts/${name}.crt".text = server.serverCertificate;
    "incus/servercerts/${name}-mtls.crt".text = server.serverCertificate;
  }) servers;
in
{
  networking.fw-proxy.noProxyPattern = lib.concatMap (server: server.noProxy) (
    lib.attrValues servers
  );

  sops.secrets.incus_client_cert_chain_pem = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    owner = "yinfeng";
    mode = "0400";
  };

  sops.secrets.incus_client_private_key_pem = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    owner = "yinfeng";
    mode = "0400";
  };

  home-manager.users.yinfeng =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.incus ];
      xdg.configFile = serverCertificates // {
        "incus/config.yml" = {
          source = (pkgs.formats.yaml { }).generate "incus-config.yml" {
            default-remote = "local";
            remotes = remotes // {
              local = {
                addr = "unix://";
                protocol = "incus";
                public = false;
              };
              images = {
                addr = "https://images.linuxcontainers.org";
                protocol = "simplestreams";
                public = true;
              };
            };
            aliases = { };
          };
        };
        "incus/client.crt".source = config.lib.file.mkOutOfStoreSymlink certificate;
        "incus/client.key".source = config.lib.file.mkOutOfStoreSymlink privateKey;
      };
    };
}
