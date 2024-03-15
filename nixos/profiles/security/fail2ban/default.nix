{ ... }:
{
  services.fail2ban = {
    enable = true;
    bantime = "10m";
  };
}
