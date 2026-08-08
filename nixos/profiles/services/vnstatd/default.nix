{ ... }:
{
  services.vnstat = {
    enable = true;
    settings = {
      UseUTC = 1;
    };
  };
}
