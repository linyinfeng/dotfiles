{ config, lib, ... }:
{
  home.file.".local/share/opencode/auth.json" =
    lib.mkIf (config.home.env.secretPaths ? opencodeAuth)
      {
        source = config.lib.file.mkOutOfStoreSymlink config.home.env.secretPaths.opencodeAuth;
      };
}
