{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  # Declaration only: which users are persisted is a system-level decision
  # (environment.global-persistence.user.users), and the home directory comes
  # from the NixOS side (users.users.<name>.home), so that users without a
  # home-manager config can be persisted too.
  options.home.global-persistence = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this user wants its home stored on persistent storage.
        Whether persistence exists at all is a system-level decision.
      '';
    };

    directories = mkOption {
      type = with types; listOf anything;
      default = [ ];
      description = ''
        A list of directories in your home directory that you want to link to persistent storage.
      '';
    };

    files = mkOption {
      type = with types; listOf anything;
      default = [ ];
      description = ''
        A list of files in your home directory you want to link to persistent storage.
      '';
    };
  };
}
