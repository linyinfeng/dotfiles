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
          "browser.search.openintab" = true;
        };
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            auto-tab-discard
            tab-session-manager
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
