{
  config,
  pkgs,
  lib,
  ...
}: let
  cacheS3Url = config.lib.self.data.cache_s3_url;
  cacheBucketName = config.lib.self.data.cache_bucket_name;
  hydraRootsDir = config.services.hydra.gcRootsDir;
in {
  systemd.services."copy-cache-li7g-com@" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      root="$1"
      echo "root = $root"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        nix store sign "$root" --recursive --key-file "$CREDENTIALS_DIRECTORY/signing-key"
        echo "push cache to cahche.li7g.com for hydra gcroot: $root"
        # use multipart-upload to avoid cloudflare limit
        nix copy --to "s3://${cacheBucketName}?endpoint=cache-overlay.li7g.com&multipart-upload=true&parallel-compression=true" "$root" --verbose
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    scriptArgs = "%I";
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
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."cache_access_key".path}"
        "signing-key:${config.sops.secrets."cache-li7g-com/key".path}"
      ];
      CPUQuota = "400%"; # limit cpu usage for parallel-compression
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
      export B2_APPLICATION_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export B2_APPLICATION_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        echo "canceling all unfinished multipart uploads..."
        backblaze-b2 cancel-all-unfinished-large-files "${cacheBucketName}"

        echo "removing narinfo cache..."
        rm -rf /var/lib/cache-li7g-com/.cache

        echo "performing gc..."
        nix-gc-s3 "${cacheBucketName}" --endpoint "${cacheS3Url}" --roots "${hydraRootsDir}" --jobs 10
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    path = with pkgs; [
      nix-gc-s3
      config.nix.package
      util-linux
      backblaze-b2
    ];
    serviceConfig = {
      Restart = "on-failure";
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "cache-li7g-com";
      LoadCredential = [
        "cache-key-id:${config.sops.secrets."cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."cache_access_key".path}"
      ];
    };
    environment =
      lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
    requiredBy = ["hydra-update-gc-roots.service"];
    after = ["hydra-update-gc-roots.service"];
  };

  sops.secrets."cache_key_id" = {
    sopsFile = config.sops-file.terraform;
  };
  sops.secrets."cache_access_key" = {
    sopsFile = config.sops-file.terraform;
  };
  sops.secrets."cache-li7g-com/key" = {
    sopsFile = config.sops-file.host;
  };

  services.notify-failure.services = [
    "copy-cache-li7g-com"
    "gc-cache-li7g-com"
  ];
}
