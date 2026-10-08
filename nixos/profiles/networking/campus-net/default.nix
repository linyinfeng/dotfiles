{ ... }:
{
  # CERNET's mirror only serves campus networks; off campus its probes fail.
  services.ncro.settings.upstreams = [
    {
      url = "https://mirrors.cernet.edu.cn/nix-channels/store";
      # below cache.nixos.org's 10, so mirrors win a latency tie
      priority = 9;
      public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    }
  ];
}
