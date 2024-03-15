{
  suites,
  profiles,
  lib,
  ...
}:
{
  imports =
    suites.wsl
    ++ suites.development
    ++ (with profiles; [
      networking.behind-fw
      networking.fw-proxy
      services.gnome-keyring
      nix.access-tokens
      users.yinfeng
    ]);

  config = lib.mkMerge [
    {
      wsl = {
        enable = true;
        defaultUser = "yinfeng";
      };
      systemd.network.wait-online.enable = false;
      home-manager.users.yinfeng =
        { suites, ... }:
        {
          imports = suites.nonGraphical;
        };
    }

    # stateVersion
    { system.stateVersion = "23.11"; }
  ];
}
