{
  config,
  pkgs,
  lib,
  ...
}:
let
  cacheS3Url = config.lib.self.data.b2_s3_api_url;
  cacheBucketName = config.lib.self.data.b2_cache_bucket_name;
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
        echo "push cache to cahche.li7g.com for hydra gcroot: $root"
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
        "cache-key-id:${config.sops.secrets."b2_cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."b2_cache_access_key".path}"
        "signing-key:${config.sops.secrets."cache-li7g-com/key".path}"
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
      export AWS_ACCESS_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export AWS_SECRET_ACCESS_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")
      export B2_APPLICATION_KEY_ID=$(cat "$CREDENTIALS_DIRECTORY/cache-key-id")
      export B2_APPLICATION_KEY=$(cat "$CREDENTIALS_DIRECTORY/cache-access-key")

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"

        echo "removing narinfo cache..."
        rm -rf /var/lib/cache-li7g-com/.cache

        echo "performing gc..."
        nix-gc-s3 "${cacheBucketName}" --endpoint "${cacheS3Url}" --roots "${hydraRootsDir}" --jobs 10

        # echo "canceling all unfinished multipart uploads..."
        # backblaze-b2 file large unfinished cancel "b2://${cacheBucketName}"
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
        "cache-key-id:${config.sops.secrets."b2_cache_key_id".path}"
        "cache-access-key:${config.sops.secrets."b2_cache_access_key".path}"
      ];
    };
    environment = lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment;
    after = [ "hydra-update-gc-roots.service" ];
  };
  systemd.timers."gc-cache-li7g-com" = {
    timerConfig.OnCalendar = "02:00";
    wantedBy = [ "timers.target" ];
  };

  sops.secrets."b2_cache_key_id" = {
    terraformOutput.enable = true;
  };
  sops.secrets."b2_cache_access_key" = {
    terraformOutput.enable = true;
  };
  sops.secrets."cache-li7g-com/key" = {
    sopsFile = config.sops-file.host;
  };
}
