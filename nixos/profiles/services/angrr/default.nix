{ config, ... }:
let
  isSimpleServer = config.system.types == [ "server" ];
in
{
  services.angrr = {
    enable = true;
    logLevel = "debug";
    settings = {
      temporary-root-policies = {
        direnv = {
          path-regex = "/\\.direnv/";
          period = "14d";
        };
        result = {
          path-regex = "/result[^/]*$";
          period = "3d";
        };
      };
      profile-policies = {
        system = {
          profile-paths = [ "/nix/var/nix/profiles/system" ];
          keep-since = if isSimpleServer then "0" else "14d";
          keep-latest-n = if isSimpleServer then 0 else 5;
          keep-current-system = true;
          keep-booted-system = true;
        };
        user = {
          profile-paths = [
            "~/.local/state/nix/profiles/profile"
            "/nix/var/nix/profiles/per-user/root/profile"
          ];
          keep-since = "1d";
          keep-latest-n = 1;
        };
      };
      touch = {
        project-globs = [
          "!.git"
          "!.jj"
        ];
      };
    };
  };
  environment.variables.ANGRR_DIRENV_LOG = "warn";
}
