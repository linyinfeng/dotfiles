{ config, pkgs, ... }:
{
  systemd.services.dotfiles-update-trigger = {
    script = ''
      github_token="$(cat "$CREDENTIALS_DIRECTORY/token")"
      curl_args=(--fail --silent --show-error
                 --location
                 --header "Accept: application/vnd.github+json"
                 --header "Authorization: Bearer $github_token")
      current_sha="$(
        curl "''${curl_args[@]}" https://api.github.com/repos/nixos/nixpkgs/branches/nixos-unstable | \
        jq '.commit.sha' --raw-output)"
      if [[ ! "$current_sha" =~ ^[0-9a-f]{40}$ ]]; then
        echo "unexpected nixos-unstable head: $current_sha" >&2
        exit 1
      fi
      # a dispatch that failed must be retried on the next tick, so only record
      # the sha once GitHub accepted it
      if [ "$current_sha" != "$(cat current-sha 2>/dev/null || true)" ]; then
        echo "triggering update.yml..."
        if ! curl "''${curl_args[@]}" \
          https://api.github.com/repos/linyinfeng/dotfiles/actions/workflows/update.yml/dispatches \
          --json '{ "ref": "main" }'; then
          echo "failed to dispatch update.yml" >&2
          exit 1
        fi
        echo "$current_sha" >current-sha
      fi
    '';
    path = with pkgs; [
      curl
      jq
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "dotfiles-update-trigger";
      WorkingDirectory = "/var/lib/dotfiles-update-trigger";
      LoadCredential = [ "token:${config.sops.secrets."github_token_dotfiles_workflow".path}" ];
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

  sops.secrets."github_token_dotfiles_workflow" = {
    predefined.enable = true;
    restartUnits = [ "dotfiles-update-trigger.service" ];
  };
}
