{ ... }:

{
  environment.global-persistence = {
    directories = [
      # service state directory
      "/var/lib"
      "/var/db"

      # trusted-settings.json
      "/root/.local/share/nix"
    ];
    etcFiles = [
      # systemd machine-id
      "/etc/machine-id"
    ];
    user.directories = [
      ".local/share/nix"
    ];
  };
}
