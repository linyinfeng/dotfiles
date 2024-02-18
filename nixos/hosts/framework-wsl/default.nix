{
  suites,
  profiles,
  lib,
  ...
}: {
  imports =
    suites.wsl
    ++ suites.development
    ++ (with profiles; [
      nix.access-tokens
      users.yinfeng
    ]);

  config = lib.mkMerge [
    {
      wsl = {
        enable = true;
        defaultUser = "yinfeng";
      };
      services.resolved.enable = lib.mkForce false;
      home-manager.users.yinfeng = {suites, ...}: {imports = suites.nonGraphical;};
    }

    # stateVersion
    {
      system.stateVersion = "23.11";
    }
  ];
}
