{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    minecraft
  ];

  environment.global-persistence.user.directories = [
    ".minecraft"
  ];
}
