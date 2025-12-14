{ ... }:
{
  services.angrr = {
    enable = true;
    logLevel = "debug";
    config = {
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
          keep-since = "14d"; # do not keep based on time
          keep-latest-n = 5; # keep latest
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
          keep-booted-system = false;
          keep-current-system = false;
        };
      };
    };
  };
}
