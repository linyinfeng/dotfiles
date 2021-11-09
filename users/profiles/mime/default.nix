{ config, lib, ... }:

let
  webBrowser = "chromium-browser.desktop";
  imageViewer = "org.gnome.eog.desktop";

  webFormats = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "text/html"
    "application/xhtml+xml"
  ];
  imageFormats = map (f: "image/${f}") [
    "jpeg"
    "bmp"
    "gif"
    "jpg"
    "pjpeg"
    "png"
    "tiff"
    "x-bmp"
    "x-gray"
    "x-icb"
    "x-ico"
    "x-png"
    "x-portable-anymap"
    "x-portable-bitmap"
    "x-portable-graymap"
    "x-portable-pixmap"
    "x-xbitmap"
    "x-xpixmap"
    "x-pcx"
    "svg+xml"
    "svg+xml-compressed"
    "vnd.wap.wbmp"
    "x-icns"
  ];

  buildMap = app: formats: lib.listToAttrs (map (f: lib.nameValuePair f app) formats);
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      buildMap [ webBrowser ] webFormats //
      buildMap [ imageViewer ] imageFormats // {
        "application/pdf" = "org.gnome.Evince.desktop";
      };
  };

  home.activation.diffMimeAppsList = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    echo "Differences of current mimeapps.list"
    # show diff and ignore result
    diff "${config.xdg.configHome}/mimeapps.list" "${config.xdg.configFile."mimeapps.list".source}" || true
    echo "Delete current mimeapps.list"
    rm "${config.xdg.configHome}/mimeapps.list"
  '';
}
