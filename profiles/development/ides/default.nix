{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # android-studio # no `preferLocalbuild`
    jetbrains.idea-ultimate
    jetbrains.clion
    jetbrains.goland
    jetbrains.pycharm-professional
  ];

  environment.global-persistence.user.directories = [
    ".config/Google"
    ".config/JetBrains"

    ".local/share/Google"
    ".local/share/JetBrains"
  ];
}
