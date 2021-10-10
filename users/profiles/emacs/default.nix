{ config, pkgs, lib, ... }:
let
  emacsConfig = ./init.el;
  emacs = (pkgs.emacsWithPackagesFromUsePackage {
    config = emacsConfig;
    package = pkgs.emacsPgtkGcc;
    alwaysEnsure = true;
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

      sarasa-gothic
    ]);
  home.file = {
    "Source/orgs/notes/templates".source = ./org-roam/templates;
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
    emacs = "emacsclient --create-frame";
    vim = "emacsclient --create-frame --tty";
  };

  home.sessionVariables = {
    EDITOR = "emacsclient";
  };

  home.file.".emacs.d/init.el".source = emacsConfig;

  home.global-persistence = {
    directories = [
      ".emacs.d"
    ];
    files = [
      ".ispell_english"
    ];
  };
}
