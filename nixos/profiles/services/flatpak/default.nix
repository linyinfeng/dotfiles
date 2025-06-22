{ ... }:
{
  services.flatpak.enable = true;
  environment.global-persistence.user.directories = [
    ".local/share/flatpak"
    ".var/app"
  ];
}
