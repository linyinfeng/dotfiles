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

  systemd.user.services.onedrive.Service.Environment =
    lib.mkIf config.home.env.proxy.enable config.home.env.proxy.stringEnvironment;

  systemd.user.tmpfiles.rules = [
    # enable onedrive service
    "L %h/.config/systemd/user/default.target.wants/onedrive.service - - - - ${config.programs.onedrive.package}/share/systemd/user/onedrive.service"
  ];

  home.global-persistence.directories = [
    ".config/onedrive"

    "OneDrive"
  ];
}
