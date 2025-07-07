{ ... }:
{
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
  environment.global-persistence.user.directories = [
    ".local/share/org.localsend.localsend_app"
  ];
}
