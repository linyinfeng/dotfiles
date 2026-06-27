{ config, osConfig, ... }:
{
  home.file.".local/share/opencode/auth.json".source =
    config.lib.file.mkOutOfStoreSymlink
      osConfig.sops.templates."opencode-auth".path;
}
