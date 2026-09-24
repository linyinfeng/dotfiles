{ ... }:
{
  world.profiles.nix = {
    access-tokens.enable = true;
    cache.enable = true;
    gc.enable = true;
    settings.enable = true;
    version.enable = true;
  };
}
