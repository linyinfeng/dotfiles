{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  rawEmacsConfig = ./init.el;
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    config = rawEmacsConfig;
    package = pkgs.emacs.override {
      withPgtk = true;
    };
    alwaysEnsure = false;
    override =
      epkgs:
      epkgs
      // (
        let
          # deadnix: skip
          lEpkgs = pkgs.nur.repos.linyinfeng.emacsPackages.override { emacsPackagesTopLevel = epkgs; };
        in
        {
          # currently nothing
          # inherit (lEpkgs) ;
        }
      );
  };
  inherit (osConfig.networking) fw-proxy;
  syncDir = "${config.home.homeDirectory}/Syncthing/Main";
  rimeShareData = pkgs.symlinkJoin {
    name = "emacs-rime-share-data";
    paths = osConfig.i18n.inputMethod.rime.rimeDataPkgs;
  };
  rimeShareDataDir = "${rimeShareData}/share/rime-data";
  emacsConfig = pkgs.replaceVars rawEmacsConfig {
    inherit syncDir rimeShareDataDir;
    ledgerFile = config.home.sessionVariables."LEDGER_FILE";
  };
in
{
  passthru = {
    inherit emacs;
  };

  home.packages = [
    emacs
  ]
  ++ (with pkgs; [
    ispell
    sqlite # org-roam
    graphviz # org-roam
    poppler_utils # pdf-tools
    ripgrep # rg
  ]);
  home.file = {
    ".emacs.d/var/orgs/templates".source = ./_org-roam/templates;
    ".emacs.d/rime" = {
      source = ../rime/_user-data;
      recursive = true;
    };
  };

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
    EDITOR = "emacsclient";
  };
  dconf.settings = lib.mkIf osConfig.programs.dconf.enable {
    "org/gnome/shell".favorite-apps = [ "emacsclient.desktop" ];
  };

  home.file.".emacs.d/init.el".source = emacsConfig;
  home.link.".ispell_english".target = "${syncDir}/dotfiles/ispell_english";

  home.global-persistence.directories = [ ".emacs.d/persist" ];

  programs.fish.interactiveShellInit = ''
    if test "$INSIDE_EMACS" = 'vterm'
      source "$EMACS_VTERM_PATH/etc/emacs-vterm.fish"
    end
  '';
}
