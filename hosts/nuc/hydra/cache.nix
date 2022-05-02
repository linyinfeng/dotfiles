{ config, pkgs, lib, ... }:

let
  hydraRootsDir = config.services.hydra.gcRootsDir;
in
{
  systemd.services."copy-cache-li7g-com" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        roots=($(fd "^.*-all-checks$" "${hydraRootsDir}" --exec echo "/nix/store/{/}"))
        nix store sign "''${roots[@]}" --recursive --key-file "$CREDENTIALS_DIRECTORY/signing-key" --verbose
        nix store sign "''${roots[@]}" --recursive --key-file "$CREDENTIALS_DIRECTORY/signing-key" --verbose --derivation
        for root in "''${roots[@]}"; do
          echo "push cache to cahche.li7g.com for hydra gcroot: $root"
          proxychains4 -q nix copy --to "s3://cache?endpoint=minio-overlay.li7g.com" "$root" --verbose
          proxychains4 -q nix copy --to "s3://cache?endpoint=minio-overlay.li7g.com" "$root" --verbose --derivation
        done
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    path = with pkgs; [
      config.nix.package
      fd
      proxychains
      util-linux
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "cache-li7g-com";
      Restart = "on-failure";
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache/keyId".path}"
        "cache-access-key:${config.sops.secrets."cache/accessKey".path}"
        "signing-key:${config.sops.secrets."cache-li7g-com/key".path}"
      ];
    };
    environment = lib.mkMerge [
      {
        HOME = "/var/lib/cache-li7g-com";
      }
      (lib.mkIf (config.networking.fw-proxy.enable)
        config.networking.fw-proxy.environment)
    ];
  };
  systemd.services."gc-cache-li7g-com" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        rm -rf /var/lib/cache-li7g-com/.cache
        nix-gc-s3 cache --endpoint https://minio.li7g.com --roots "${hydraRootsDir}"
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    path = with pkgs; [
      nix-gc-s3
      config.nix.package
      util-linux
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "cache-li7g-com";
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
  sops.secrets."cache-li7g-com/key".sopsFile = config.sops.secretsDir + /nuc.yaml;
}
