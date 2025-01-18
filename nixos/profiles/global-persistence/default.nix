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
      # https://nix-community.github.io/preservation/examples.html#compatibility-with-systemds-conditionfirstboot
      {
        file = "/etc/machine-id";
        inInitrd = true;
      }
    ];
    user.directories = [ ".local/share/nix" ];
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
