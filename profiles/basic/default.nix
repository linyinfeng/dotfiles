{ ... }:

{
  imports = [
    ../global-persistence
    ../networking/network-manager
    ../networking/resolved
    ../security/fail2ban
    ../security/firewall
    ../security/polkit
    ../services/clean-gcroots
    ../services/gnupg
  ];
}
