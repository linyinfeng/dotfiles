{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  {
    programs.desktop-files.favorites = lib.mkOrder 1000 [ "zen" ];
  }
  {
    programs.google-chrome = {
      enable = true;
      commandLineArgs = [
        # web features
        "--enable-experimental-web-platform-features"

        # video acceleration
        "--enable-features=AcceleratedVideoDecodeLinuxGL"
      ];
    };

    home.global-persistence.directories = [ ".config/google-chrome" ];
  }
  {
    programs.firefox = {
      enable = true;
      configPath = "${config.xdg.configHome}/mozilla/firefox";
      profiles = {
        main = {
          id = 0;
          isDefault = true;
          settings = {
            "sidebar.verticalTabs" = true;
            "browser.search.openintab" = true;
            "browser.urlbar.openintab" = true;
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
      directories = [ ".config/mozilla/firefox" ];
    };
  }

  {
    home.packages = with pkgs; [
      zen-browser
    ];
    home.global-persistence = {
      directories = [ ".config/zen" ];
    };
  }
]
