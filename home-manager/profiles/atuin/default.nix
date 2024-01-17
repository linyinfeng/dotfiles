{ osConfig, ... }:

{
  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.li7g.com";
    };
  };
}
