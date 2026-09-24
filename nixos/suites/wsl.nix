{ ... }:
{
  world = {
    modules.external.nixos-wsl.enable = true;
    profiles = {
      i18n.input-method.enable = true;
      system.types.workstation.enable = true;
      wsl.settings.enable = true;
    };
    suites = {
      base.enable = true;
      network.enable = true;
    };
  };
}
