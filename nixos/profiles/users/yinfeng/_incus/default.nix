{
  config,
  ...
}:
let
  certificate = config.sops.secrets.incus_client_cert_chain_pem.path;
  privateKey = config.sops.secrets.incus_client_private_key_pem.path;
in
{
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
        "incus/client.crt".source = config.lib.file.mkOutOfStoreSymlink certificate;
        "incus/client.key".source = config.lib.file.mkOutOfStoreSymlink privateKey;
      };
    };
}
