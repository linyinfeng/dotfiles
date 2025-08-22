{ ... }:
{
  programs.firefox = {
    enable = true;
    profiles = {
      main = {
        id = 0;
        isDefault = true;
        settings = {
          "network.proxy.type" = 0; # use proxy plugins to select proxies
          # "media.ffmpeg.vaapi.enabled" = true;
          # "media.ffvpx.enabled" = false;
          # "media.rdd-vpx.enabled" = false;
          # "security.sandbox.content.level" = 0;
          # "media.navigator.mediadatadecoder_vpx_enabled" = true;
        };
      };
    };
  };
  stylix.targets.firefox.profileNames = [ "main" ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  home.global-persistence = {
    directories = [ ".mozilla" ];
  };
}
