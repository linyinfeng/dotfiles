{ pkgs, ... }:

{
  programs = {
    traceroute.enable = true;
    mtr.enable = true;
    wireshark.enable = true;
  };
  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    inetutils
    iputils
    whois
  ];
}
