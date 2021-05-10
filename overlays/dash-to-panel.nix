final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    dash-to-panel = prev.gnomeExtensions.dash-to-panel.overrideAttrs
      (old: rec {
        name = "gnome-shell-dash-to-panel-${version}";
        version = "git-a4224f4";
        src = prev.fetchFromGitHub {
          owner = "home-sweet-gnome";
          repo = "dash-to-panel";
          rev = "a4224f4acc52a1b69e43951aaad1864c6db54e90";
          sha256 = "sha256-mofnSZjoL0Ju+ku84cnu4sd+nK/KNBgUKlIJznO/x2g=";
        };
      });
  };
}
