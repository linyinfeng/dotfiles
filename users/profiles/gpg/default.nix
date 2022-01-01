{ pkgs, ... }:

{
  programs.gpg = {
    enable = true;
    scdaemonSettings = {
      # canokey support
      card-timeout = "5";
      disable-ccid = true;
    };
  };
  home.packages = with pkgs; [
    haskellPackages.hopenpgp-tools
  ];
}
