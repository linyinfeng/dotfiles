{ ... }:
{
  environment.global-persistence = {
    directories = [
      # service state directory
      "/var/lib"
      "/var/db"
    ];
    files = [
      # systemd machine-id
      "/etc/machine-id"
    ];
    user.directories = [ ".local/share/nix" ];
  };

  # TODO wait for https://github.com/nix-community/impermanence/issues/229
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
