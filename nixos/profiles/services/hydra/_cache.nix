{
  config,
  pkgs,
  lib,
  ...
}:
{
  systemd.services."copy-cache-li7g-com@" = {
    script = ''
      root="$1"
      echo "root = $root"

      (
        echo "wait for lock"
        flock 200
        echo "enter critical section"
        attic login --set-default main "https://atticd.endpoints.li7g.com" "$(cat "$CREDENTIALS_DIRECTORY/token")"
        attic push dotfiles "$root"
      ) 200>/var/lib/cache-li7g-com/lock
    '';
    scriptArgs = "%I";
    path = with pkgs; [
      attic-client
      util-linux
    ];
    serviceConfig = {
      User = "hydra";
      Group = "hydra";
      Type = "oneshot";
      StateDirectory = "cache-li7g-com";
      LoadCredential = [
        "token:${config.sops.secrets."attic_dotfiles_push_token".path}"
      ];
      CPUQuota = "200%"; # limit cpu usage for parallel-compression
    };
    environment = lib.mkMerge [
      { HOME = "/var/lib/cache-li7g-com"; }
      (lib.mkIf config.networking.fw-proxy.enable config.networking.fw-proxy.environment)
    ];
  };
  sops.secrets."attic_dotfiles_push_token" = {
    predefined.enable = true;
  };
}
