{ pkgs, ... }:

{
  home.packages = with pkgs; [ proxychains ];

  home.file.".proxychains/proxychains.conf" = {
    source = ./proxychains.conf;
  };
}
