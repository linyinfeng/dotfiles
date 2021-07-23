{ pkgs, ... }:

{
  programs.git = {
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.ff = "only";
      credential.helper = "libsecret";
    };
  };
  home.packages = with pkgs; [
    git-crypt
  ];
}
