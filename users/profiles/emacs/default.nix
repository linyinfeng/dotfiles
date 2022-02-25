{ config, pkgs, lib, inputs, ... }:
let
  emacsConfig = ./init.el;
  emacs = (pkgs.emacsWithPackagesFromUsePackage {
    config = emacsConfig;
    package = pkgs.emacsPgtkGcc;
    alwaysEnsure = true;
    override = epkgs: epkgs // {
      webkit = pkgs.callPackage inputs.emacs-webkit {
        inherit (epkgs) trivialBuild;
      };
      ligature = epkgs.trivialBuild {
        inherit (pkgs.sources.ligature-el) pname version src;
      };
    };
  });
  fw-proxy = config.passthrough.systemConfig.networking.fw-proxy;
  syncPath = "/var/lib/syncthing/Main";
in
{
  home.packages = [ emacs ] ++
    (with pkgs; [
      ispell
      sqlite # org-roam
      graphviz # org-roam
      poppler_utils # pdf-tools
      ripgrep # rg
    ]);
  home.file = {
    ".emacs.d/var/orgs/templates".source = ./org-roam/templates;
  };
  fonts.fontconfig.enable = lib.mkDefault true; # for fira-code-symbols

  services.emacs = {
    enable = true;
    package = emacs;
    client.enable = true;
  };
  systemd.user.services.emacs = {
    Service.Environment = lib.mkIf fw-proxy.enable fw-proxy.stringEnvironment;
  };

  home.shellAliases = {
    en = "emacsclient --no-wait";
    ecn = "emacsclient --create-frame --no-wait";
    ect = "emacsclient --create-frame --tty";
  };
  home.sessionVariables = {
    EDITOR = "emacsclient --create-frame";
  };
  xdg.mimeApps.associations.added = {
    "text/plain" = "emacsclient.desktop";
  };

  home.file.".emacs.d/init.el".source = emacsConfig;

  home.global-persistence = {
    directories = [
      ".emacs.d"
    ];
  };
  home.link.".ispell_english".target = "${syncPath}/dotfiles/ispell_english";
}
