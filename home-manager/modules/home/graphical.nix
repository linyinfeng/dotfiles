{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.home.graphical;
  sysGraphical =
    osConfig.services.xserver.enable
    || osConfig.services.greetd.enable;
in
  with lib; {
    options.home.graphical = lib.mkOption {
      type = types.bool;
      description = ''
        Whether to enable graphical applications.
      '';
    };

    config = {
      home.graphical = lib.mkDefault sysGraphical;
    };
  }
