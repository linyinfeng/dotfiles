{ config, pkgs, lib, ... }:

{
  systemd.services."gc-cache-li7g-com" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      hydra_gcroot="/nix/var/nix/gcroots/hydra"
      nix-gc-s3 cache --endpoint https://minio.li7g.com --roots "$hydra_gcroot"
    '';
    path = with pkgs; [
      nix-gc-s3
      config.nix.package
    ];
    serviceConfig = {
      DynamicUser = true;
      Group = "hydra";
      StateDirectory = "dotfiles-channel-update";
      Restart = "on-failure";
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache/keyId".path}"
        "cache-access-key:${config.sops.secrets."cache/accessKey".path}"
      ];
    };
    environment = lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
    requiredBy = [ "hydra-update-gc-roots.service" ];
    after = [ "hydra-update-gc-roots.service" ];
  };
}
