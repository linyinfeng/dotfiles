{
  lib,
  osConfig,
  config,
  ...
}:
{
  programs.onedrive = {
    enable = true;
    settings = {
      # currently nothing
    };
  };

  systemd.user.services.onedrive.Service.Environment =
    lib.mkIf osConfig.networking.fw-proxy.enable osConfig.networking.fw-proxy.stringEnvironment;

  systemd.user.tmpfiles.rules = [
    # enable onedrive service
    "L %h/.config/systemd/user/default.target.wants/onedrive.service - - - - ${config.programs.onedrive.package}/share/systemd/user/onedrive.service"
  ];

  home.global-persistence.directories = [
    ".config/onedrive"

    "OneDrive"
  ];
}
