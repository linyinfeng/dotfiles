{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;
    extraConfig = {
      pull.ff = "only";
      credential.helper = "libsecret";
    };
  };
}
