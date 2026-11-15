{
  config,
  ...
}:
let
  remoteName = "ostrich";
  certificate = config.sops.secrets.incus_client_cert_chain_pem.path;
  privateKey = config.sops.secrets.incus_client_private_key_pem.path;
  serverCertificate = config.lib.self.data.acme_li7g_com_certificate_pem;
in
{
  networking.fw-proxy.noProxyPattern = [ "ostrich-incus.bunny-mountain.ts.net" ];

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
      xdg.configFile = {
        "incus/config.yml" = {
          source = (pkgs.formats.yaml { }).generate "incus-config.yml" {
            default-remote = "local";
            remotes = {
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
              ${remoteName} = {
                addr = "https://192.168.3.6:8443,https://ostrich-incus.bunny-mountain.ts.net:8443";
                auth_type = "tls";
                protocol = "incus";
                public = false;
              };
            };
            aliases = { };
          };
        };
        "incus/servercerts/${remoteName}.crt".text = serverCertificate;
        "incus/client.crt".source = config.lib.file.mkOutOfStoreSymlink certificate;
        "incus/client.key".source = config.lib.file.mkOutOfStoreSymlink privateKey;
      };
    };
}
