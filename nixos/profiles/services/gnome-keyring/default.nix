{ ... }:
{
  services.gnome.gnome-keyring.enable = true;
  environment.global-persistence.user.directories = [ ".local/share/keyrings" ];
}
