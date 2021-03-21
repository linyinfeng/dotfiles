{ config, pkgs, ... }:

{
  imports = [
    ./persist
  ];

  users.users.yinfeng = {
    uid = 1000;
    hashedPassword = import ../../secrets/users/yinfeng/hashedPassword.nix;
    isNormalUser = true;
    shell = pkgs.zsh;
    group = "yinfeng";
    extraGroups = [
      "users"
      "wheel"
      "networkmanager"
      "adbusers"
      "docker"
      "libvirtd"
    ];
  };

  users.groups.yinfeng = {
    gid = 1000;
  };

  home-manager.users.yinfeng = {
    imports = [
      (import ../profiles/passthrough config)

      ../profiles/desktop-applications
      ../profiles/digital-paper
      ../profiles/direnv
      ../profiles/emacs
      ../profiles/git
      ../profiles/gnome
      ../profiles/ides
      ../profiles/latex
      ../profiles/onedrive
      ../profiles/proxychains
      ../profiles/rime
      ../profiles/scripts
      ../profiles/shells
      ../profiles/tools
      ../profiles/vscode

      ./user-profiles/git
    ];
  };
}
