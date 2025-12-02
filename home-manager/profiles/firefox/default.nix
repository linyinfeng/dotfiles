{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    profiles = {
      main = {
        id = 0;
        isDefault = true;
        settings = {
          "sidebar.verticalTabs" = true;
        };
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            auto-tab-discard
          ];
        };
      };
    };
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  home.global-persistence = {
    directories = [ ".mozilla" ];
  };
}
