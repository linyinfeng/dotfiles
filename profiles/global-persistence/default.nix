{ ... }:

{
  environment.global-persistence = {
    directories = [
      "/var/lib/systemd/coredump"
      "/var/db/sudo/lectured"
      "/root/.local/share/nix" # trusted-settings.json
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
