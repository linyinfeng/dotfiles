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
    };
  });
  fw-proxy = config.passthrough.systemConfig.networking.fw-proxy;
in
{
  home.packages = [ emacs ] ++
    (with pkgs; [
      ispell
      agda # agda mode
      sqlite # org-roam
      graphviz # org-roam
      poppler_utils # pdf-tools
      ripgrep # rg

      sarasa-gothic
    ]);
  home.file = {
    "Roaming/orgs/notes/templates".source = ./org-roam/templates;
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
    ec = "emacsclient --create-frame";
    ect = "emacsclient --create-frame --tty";
  };

  home.sessionVariables = {
    EDITOR = config.home.shellAliases.ect;
  };

  home.file.".emacs.d/init.el".source = emacsConfig;

  home.global-persistence = {
    directories = [
      ".emacs.d"
    ];
  };
  home.link.".ispell_english".target = "${config.home.roaming.path}/dotfiles/ispell_english";
}
