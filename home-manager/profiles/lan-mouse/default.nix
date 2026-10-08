{ ... }:
{
  programs.lan-mouse.enable = true;

  # Peers pin the daemon's TLS identity from here, so it has to survive an
  # impermanent boot.
  home.global-persistence.directories = [ ".config/lan-mouse" ];
}
