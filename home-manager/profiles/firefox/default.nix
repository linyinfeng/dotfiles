{
  config,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
    profiles = {
      main = {
        id = 0;
        isDefault = true;
        settings = {
          "media.ffmpeg.vaapi.enabled" = true;
          # "media.ffvpx.enabled" = false;
          # "media.rdd-vpx.enabled" = false;
          # "security.sandbox.content.level" = 0;
          "media.navigator.mediadatadecoder_vpx_enabled" = true;
        };
      };
    };
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  home.global-persistence = {
    directories = [
      ".mozilla"
    ];
  };
}
