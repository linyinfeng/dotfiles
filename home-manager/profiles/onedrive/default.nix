{
  lib,
  config,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.onedrive = {
    enable = true;
    settings = {
      # currently nothing
    };
  };

  # The package ships a complete user unit. Declare it here rather than through
  # `systemd.user.services`, which would generate an unrelated unit of the same
  # name that shadows this one and has no `ExecStart`. Home Manager has no
  # drop-in option, so the proxy environment is added as one by hand.
  xdg.configFile = lib.mkMerge [
    {
      "systemd/user/onedrive.service".source =
        "${config.programs.onedrive.package}/share/systemd/user/onedrive.service";

      "systemd/user/default.target.wants/onedrive.service".source =
        "${config.programs.onedrive.package}/share/systemd/user/onedrive.service";
    }

    (lib.mkIf config.home.env.proxy.enable {
      "systemd/user/onedrive.service.d/proxy.conf".text = lib.concatLines (
        [ "[Service]" ] ++ map (variable: "Environment=${variable}") config.home.env.proxy.stringEnvironment
      );
    })
  ];

  home.global-persistence.directories = [
    ".config/onedrive"

    "OneDrive"
  ];
}
