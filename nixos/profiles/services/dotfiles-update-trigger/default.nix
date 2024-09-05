{ config, pkgs, ... }:
{
  systemd.services.dotfiles-update-trigger = {
    script = ''
      github_token="$(cat "$CREDENTIALS_DIRECTORY/token")"
      curl_args=(--location
                 --header "Accept: application/vnd.github+json"
                 --header "Authorization: Bearer $github_token")
      current_sha="$(
        curl "''${curl_args[@]}" https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable | \
        jq '.commit.sha' --raw-output)"
      if [ -f recorded-sha ] && [ "$(cat recorded-sha)" != "$current_sha" ]; then
        echo "triggering update.yml..."
        curl "''${curl_args[@]}" \
          https://api.github.com/repos/linyinfeng/dotfiles/actions/workflows/update.yml/dispatches \
          --json '{ "ref": "main" }'
      fi
      echo "$current_sha" >recorded-sha
    '';
    path = with pkgs; [
      curl
      jq
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "dotfiles-update-trigger";
      WorkingDirectory = "/var/lib/dotfiles-update-trigger";
      LoadCredential = [ "token:${config.sops.secrets."dotfiles-workflow/github-token".path}" ];
    };
    wantedBy = [ "multi-user.service" ];
  };

  systemd.timers.dotfiles-update-trigger = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitInactiveSec = 600;
      OnBootSec = 300;
      AccuracySec = 300;
    };
  };

  sops.secrets."dotfiles-workflow/github-token" = {
    sopsFile = config.sops-file.host;
    restartUnits = [ "dotfiles-update-trigger.service" ];
  };
}
