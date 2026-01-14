{
  config,
  pkgs,
  lib,
  ...
}:
let
  cacheBucketName = config.lib.self.data.r2_cache_bucket_name;
  hydraRootsDir = config.services.hydra.gcRootsDir;
in
{
  systemd.services."copy-cache-li7g-com@" = {
    script = ''
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      export AWS_EC2_METADATA_DISABLED=true

      root="$1"
      echo "root = $root"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        nix store sign "$root" --recursive --key-file "$CREDENTIALS_DIRECTORY/signing-key"
        echo "push cache to cache.li7g.com for hydra gcroot: $root"
        # TODO set multipart-upload=true
        # currently this does not work on aws-s3-reverse-proxy
        nix copy --to "s3://${cacheBucketName}?endpoint=cache-overlay.ts.li7g.com&parallel-compression=true&compression=zstd" "$root" --verbose
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
        "cache-key-id:${config.sops.secrets."r2_cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."r2_cache_access_key".path}"
        "signing-key:${config.sops.secrets."cache_li7g_com_key".path}"
      ];
      CPUQuota = "200%"; # limit cpu usage for parallel-compression
    };
    environment = lib.mkMerge [
      { HOME = "/var/lib/cache-li7g-com"; }
      # (lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment)
    ];
  };
  systemd.services."gc-cache-li7g-com" = {
    script = ''
      export ENDPOINT=$(cat "$CREDENTIALS_DIRECTORY/s3-endpoint")
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        echo "removing narinfo cache..."
        rm -rf /var/lib/cache-li7g-com/.cache

        echo "performing gc..."
        nix-gc-s3 "${cacheBucketName}" --endpoint "https://$ENDPOINT" --roots "${hydraRootsDir}" --jobs 10
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    path = with pkgs; [
      nix-gc-s3
      config.nix.package
      util-linux
    ];
    serviceConfig = {
      Restart = "on-failure";
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "cache-li7g-com";
      LoadCredential = [
        "s3-endpoint:${config.sops.secrets."r2_s3_api_url".path}"
        "cache-key-id:${config.sops.secrets."r2_cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."r2_cache_access_key".path}"
      ];
    };
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    after = [ "hydra-update-gc-roots.service" ];
  };
  systemd.timers."gc-cache-li7g-com" = {
    timerConfig.OnCalendar = "02:00";
    wantedBy = [ "timers.target" ];
  };

  sops.secrets."r2_s3_api_url" = {
    terraformOutput.enable = true;
  };
  sops.secrets."r2_cache_key_id" = {
    terraformOutput.enable = true;
  };
  sops.secrets."r2_cache_access_key" = {
    terraformOutput.enable = true;
  };
  sops.secrets."cache_li7g_com_key" = {
    predefined.enable = true;
  };
}
