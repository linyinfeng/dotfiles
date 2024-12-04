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
}
