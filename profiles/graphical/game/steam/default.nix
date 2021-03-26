{ ... }:

{
  programs.steam.enable = true;
  environment.global-persistence.user.directories = [
    ".steam"
    ".local/share/Steam"
  ];
}
