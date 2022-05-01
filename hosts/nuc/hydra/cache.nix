{ config, pkgs, lib, ... }:

{
  systemd.services."copy-cache-li7g-com" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      hydra_gcroot="/nix/var/nix/gcroots/hydra"
      for item in $(ls "$hydra_gcroot" | grep "all-checks\$"); do
        echo "push cache to cahche.li7g.com for hydra gcroot: $hydra_gcroot/$item"
        proxychains4 -q \
          nix copy --to "s3://cache?endpoint=minio-overlay.li7g.com" "/nix/store/$item" --verbose
      done
    '';
    path = with pkgs; [
      config.nix.package
      proxychains
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "copy-cache-li7g-com";
      Restart = "on-failure";
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache/keyId".path}"
        "cache-access-key:${config.sops.secrets."cache/accessKey".path}"
      ];
    };
    environment = lib.mkMerge [
      {
        HOME = "/var/lib/copy-cache-li7g-com";
      }
      (lib.mkIf (config.networking.fw-proxy.enable)
        config.networking.fw-proxy.environment)
    ];
  };
  systemd.services."gc-cache-li7g-com" = {
    script = ''
      rm -rf /var/lib/copy-cache-li7g-com/.cache
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
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
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

  sops.secrets."cache/keyId".sopsFile = config.sops.secretsDir + /nuc.yaml;
  sops.secrets."cache/accessKey".sopsFile = config.sops.secretsDir + /nuc.yaml;
}
