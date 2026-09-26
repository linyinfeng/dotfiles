{
  config,
  lib,
  pkgs,
  ...
}:
let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  home.packages =
    with pkgs;
    [
      # keep-sorted start
      amberol
      calibre
      decibels
      file-roller
      geary
      gimp
      # gnuradio # unused
      gnome-text-editor
      inkscape
      kicad
      llm-agents.chatgpt
      loupe
      meld
      mission-center
      moonlight-qt
      nautilus
      papers
      picard
      praat
      qq
      telegram-desktop
      totem
      transmission-remote-gtk
      virt-manager
      virt-viewer
      xournalpp
      zotero
      # keep-sorted end
    ]
    # TODO: drop the isAarch64 guard once libreoffice builds on aarch64-linux
    # (buildPhase fails there: git not found, dragonbox tarball missing).
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [ libreoffice ]
    ++ optionalPkg [ "teamspeak6-client" ]
    ++ optionalPkg [
      "nur"
      "repos"
      "linyinfeng"
      "wemeet"
    ];

  xdg.desktopEntries = {
    qq = {
      name = "QQ";
      exec = "qq --enable-wayland-ime %U";
      icon = "qq";
      categories = [ "Network" ];
      settings.StartupWMClass = "QQ";
    };
    element-desktop = {
      name = "Element";
      genericName = "Matrix Client";
      exec = "element-desktop --enable-wayland-ime %U";
      icon = "element";
      mimeType = [ "x-scheme-handler/element" ];
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      comment = "A feature-rich client for Matrix.org";
      settings.StartupWMClass = "Element";
    };
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [
        "qemu:///system"
        "qemu+ssh://root@nuc/system"
      ];
    };
    "io/missioncenter/MissionCenter" = {
      performance-page-cpu-graph = 2;
    };
  };

  home.global-persistence = {
    directories = [
      ".ts3client"
      ".zotero"
      ".goldendict"

      ".config/Codex"
      ".config/calibre"
      ".config/Element"
      ".config/icalingua"
      ".config/QQ"
      ".config/unity3d" # unity3d game saves
      ".config/transmission-remote-gtk"
      ".config/MusicBrainz" # picard configs
      ".config/inkscape"
      ".config/Moonlight Game Streaming Project"
      ".config/TeamSpeak"
      ".config/kicad"

      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/geary"
      ".local/share/kicad"

      "Zotero"
    ];
  };
}
