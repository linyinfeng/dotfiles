{ config, pkgs, lib, inputs, osConfig, ... }:
let
  rawEmacsConfig = ./init.el;
  emacs = (pkgs.emacsWithPackagesFromUsePackage {
    config = rawEmacsConfig;
    package = pkgs.emacsPgtk;
    alwaysEnsure = false;
    override = epkgs: epkgs // {
      inherit (epkgs.melpaPackages) telega;
      ligature = epkgs.trivialBuild {
        inherit (pkgs.sources.ligature-el) pname version src;
      };
      # TODO wait for https://nixpk.gs/pr-tracker.html?pr=219469
      rime = epkgs.rime.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [
          pkgs.librime
        ];
        preBuild = (old.preBuild or "") + ''
          make lib
          mkdir -p /build/rime-lib
          cp *.so /build/rime-lib
        '';
        postInstall = (old.postInstall or "") + ''
          install -m444 -t $out/share/emacs/site-lisp/elpa/rime-* /build/rime-lib/*.so
        '';
      });
    };
  });
  fw-proxy = osConfig.networking.fw-proxy;
  syncDir = "${config.home.homeDirectory}/Syncthing/Main";
  rimeShareData = pkgs.symlinkJoin {
    name = "emacs-rime-share-data";
    paths = osConfig.i18n.inputMethod.rime.packages;
  };
  rimeShareDataDir = "${rimeShareData}/share/rime-data";
  emacsConfig = pkgs.substituteAll {
    src = rawEmacsConfig;
    inherit syncDir rimeShareDataDir;
    telegaProxyEnable = if fw-proxy.enable then "t" else "nil";
    telegaProxyServer = "localhost";
    telegaProxyPort = if fw-proxy.enable then fw-proxy.mixinConfig.mixed-port else "nil";
  };
in
{
  passthru = { inherit emacs; };

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
    ".emacs.d/var/pyim/greatdict.pyim.gz".source = "${pkgs.sources.pyim-greatdict.src}/pyim-greatdict.pyim.gz";
    ".emacs.d/rime" = {
      source = ./rime;
      recursive = true;
    };
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
    EDITOR = "emacsclient";
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
  home.link.".ispell_english".target = "${syncDir}/dotfiles/ispell_english";

  programs.fish.interactiveShellInit = ''
    if test "$INSIDE_EMACS" = 'vterm'
      source "$EMACS_VTERM_PATH/etc/emacs-vterm.fish"
    end
  '';
}
