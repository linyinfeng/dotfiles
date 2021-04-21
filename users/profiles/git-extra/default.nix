{ pkgs, ... }:

{
  programs.git = {
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      pull.ff = "only";
      credential.helper = "libsecret";
    };
  };
  home.packages = with pkgs; [
    git-crypt
  ];
}
