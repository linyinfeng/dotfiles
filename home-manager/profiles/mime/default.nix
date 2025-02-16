{ config, lib, ... }:
let
  webFormats = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "text/html"
    "application/xhtml+xml"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
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
  archiveFormats = map (f: "application/${f}") [
    "x-tar"
    "x-7z-compressed"
    "x-rar-compressed"
    "x-gtar"
    "zip"
  ];
  audioFormats = map (f: "audio/${f}") [
    "x-vorbis+ogg"
    "ogg"
    "vorbis"
    "x-vorbis"
    "x-speex"
    "opus"
    "flac"
    "x-flac"
    "x-ms-asf"
    "x-ms-asx"
    "x-ms-wax"
    "x-ms-wma"
    "x-pn-windows-acm"
    "vnd.rn-realaudio"
    "x-pn-realaudio"
    "x-pn-realaudio-plugin"
    "x-real-audio"
    "x-realaudio"
    "mpeg"
    "mpg"
    "mp1"
    "mp2"
    "mp3"
    "x-mp1"
    "x-mp2"
    "x-mp3"
    "x-mpeg"
    "x-mpg"
    "aac"
    "m4a"
    "mp4"
    "x-m4a"
    "x-aac"
    "x-matroska"
    "webm"
    "3gpp"
    "3gpp2"
    "AMR"
    "AMR-WB"
    "mpegurl"
    "x-mpegurl"
    "scpls"
    "x-scpls"
    "dv"
    "x-aiff"
    "x-pn-aiff"
    "wav"
    "x-pn-au"
    "x-pn-wav"
    "x-wav"
    "x-adpcm"
    "ac3"
    "eac3"
    "vnd.dts"
    "vnd.dts.hd"
    "vnd.dolby.heaac.1"
    "vnd.dolby.heaac.2"
    "vnd.dolby.mlp"
    "basic"
    "midi"
    "x-ape"
    "x-gsm"
    "x-musepack"
    "x-tta"
    "x-wavpack"
    "x-shorten"
    "x-it"
    "x-mod"
    "x-s3m"
    "x-xm"
  ];
  videoFormats = map (f: "video/${f}") [
    "x-ogm+ogg"
    "ogg"
    "x-ogm"
    "x-theora+ogg"
    "x-theora"
    "x-ms-asf"
    "x-ms-asf-plugin"
    "x-ms-asx"
    "x-ms-wm"
    "x-ms-wmv"
    "x-ms-wmx"
    "x-ms-wvx"
    "x-msvideo"
    "divx"
    "msvideo"
    "vnd.divx"
    "avi"
    "x-avi"
    "vnd.rn-realvideo"
    "mp2t"
    "mpeg"
    "mpeg-system"
    "x-mpeg"
    "x-mpeg2"
    "x-mpeg-system"
    "mp4"
    "mp4v-es"
    "x-m4v"
    "quicktime"
    "x-matroska"
    "webm"
    "3gp"
    "3gpp"
    "3gpp2"
    "vnd.mpegurl"
    "dv"
    "x-anim"
    "x-nsv"
    "fli"
    "flv"
    "x-flc"
    "x-fli"
    "x-flv"
  ];
  wordFormats = map (f: "application/${f}") [
    "msword"
    "vnd.openxmlformats-officedocument.wordprocessingml.document"
    "vnd.openxmlformats-officedocument.wordprocessingml.template"
    "vnd.ms-word.document.macroEnabled.12"
    "vnd.ms-word.template.macroEnabled.12"
  ];
  excelFormats = map (f: "application/${f}") [
    "vnd.ms-excel"
    "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    "vnd.openxmlformats-officedocument.spreadsheetml.template"
    "vnd.ms-excel.sheet.macroEnabled.12"
    "vnd.ms-excel.template.macroEnabled.12"
    "vnd.ms-excel.addin.macroEnabled.12"
    "vnd.ms-excel.sheet.binary.macroEnabled.12"
  ];
  pptFormats = map (f: "application/${f}") [
    "vnd.ms-powerpoint"
    "vnd.openxmlformats-officedocument.presentationml.presentation"
    "vnd.openxmlformats-officedocument.presentationml.template"
    "vnd.openxmlformats-officedocument.presentationml.slideshow"
    "vnd.ms-powerpoint.addin.macroEnabled.12"
    "vnd.ms-powerpoint.presentation.macroEnabled.12"
    "vnd.ms-powerpoint.template.macroEnabled.12"
    "vnd.ms-powerpoint.slideshow.macroEnabled.12"
  ];

  buildMap = app: formats: lib.listToAttrs (map (f: lib.nameValuePair f app) formats);
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      buildMap [ "chromium-browser.desktop" ] webFormats
      // buildMap [ "org.gnome.Loupe.desktop" ] imageFormats
      // buildMap [ "org.gnome.FileRoller.desktop" ] archiveFormats
      // buildMap [ "io.bassi.Amberol.desktop" ] audioFormats
      // buildMap [ "com.github.rafostar.Clapper.desktop" ] videoFormats
      // buildMap [ "writer.desktop" ] wordFormats
      // buildMap [ "calc.desktop" ] excelFormats
      // buildMap [ "impress.desktop" ] pptFormats
      // {
        "text/plain" = "org.gnome.TextEditor.desktop";
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "x-scheme-handler/mailto" = [ "org.gnome.Geary.desktop" ];
      };
  };

  home.activation.diffMimeAppsList = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    mimeapps="${config.xdg.configHome}/mimeapps.list"
    if [ -e "$mimeapps" ]; then
      echo "Differences of current mimeapps.list"
      # show diff and ignore result
      diff "$mimeapps" "${config.xdg.configFile."mimeapps.list".source}" || true
      echo "Delete current mimeapps.list"
      rm "$mimeapps"
    fi
  '';
}
