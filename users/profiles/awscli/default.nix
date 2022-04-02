{ pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli
  ];
  home.global-persistence.directories = [
    ".aws"
  ];
}
