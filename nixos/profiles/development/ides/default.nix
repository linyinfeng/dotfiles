{ pkgs, ... }:
{
  # persistence directories for jetbrains ides
  environment.global-persistence.user.directories = [
    ".config/Google"
    ".config/JetBrains"

    ".local/share/Google"
    ".local/share/JetBrains"
  ];
}
