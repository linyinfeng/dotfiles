{ config, pkgs, lib, ... }:
let
  homeDir = "/home/yinfeng";
  mapHome = map (dir: "${homeDir}/${dir}");
in
{
  environment.global-persistence = {
    softLinkFiles = mapHome [
      ".face"
      ".zsh_history"
      ".config/mimeapps.list"
      ".ssh/authorized_keys"
      ".ssh/config"
      ".ssh/id_rsa"
      ".ssh/id_rsa.pub"
      ".ssh/known_hosts"
      ".ispell_english"
    ];

    directories = mapHome [
      ".gnupg"

      ".ts3client"
      ".wine"
      ".mozilla"
      ".weechat"
      ".emacs.d"
      ".vscode"
      ".vscode-server"
      ".rustup"
      ".cargo"
      ".cabal"
      ".nixops"
      ".goldendict"
      ".dpapp"

      ".config/nix"
      ".config/dconf"
      ".config/clash"
      ".config/onedrive"
      ".config/chromium"
      ".config/transmission-daemon"
      ".config/gh"
      ".config/gnome-boxes"
      ".config/libvirt"
      ".config/JetBrains"
      ".config/Google"
      ".config/goa-1.0" # gnome accounts
      ".config/Code"
      ".config/ibus/rime"
      ".config/obs-studio"
      ".config/Element"
      ".config/calibre"
      ".config/cachix"
      ".config/unity3d/Team Cherry" # hollow knight saves

      ".cache/nix-index"

      ".local/share/zoxide"
      ".local/share/Anki2"
      ".local/share/TelegramDesktop"
      ".local/share/keyrings"
      ".local/share/direnv"
      ".local/share/gnome-boxes"
      ".local/share/JetBrains"
      ".local/share/Google"
      ".local/share/webkitgtk" # gnome accounts
      ".local/share/geary"
      ".local/share/flatpak"
      ".local/share/applications"

      ".var/app" # flatpak application data

      ".steam"
      ".local/share/Steam"

      "Desktop"
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Public"
      "Templates"
      "Videos"

      ".zotero"
      "Zotero"

      "OneDrive"

      "Source"
      "Roaming"
      "Local"
    ];
  };
}
