{ pkgs, ... }:

{
  programs.git = {
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.ff = "only";
      credential.helper = "libsecret";

      # fish git status
      bash.showInformativeStatus = true;
    };
  };
  home.packages = with pkgs; [
    git-crypt
  ];
}
