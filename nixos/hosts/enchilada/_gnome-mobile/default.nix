# https://github.com/NixOS/mobile-nixos/pull/576
{pkgs, ...}: let
  source-gnome-shell = pkgs.nur.repos.linyinfeng.sources.gnome-shell-mobile-shell;
  source-mutter = pkgs.nur.repos.linyinfeng.sources.mutter-mobile-shell;
in {
  nixpkgs.overlays = [
    (self: super: {
      gnome = super.gnome.overrideScope' (gself: gsuper: {
        gnome-shell = gsuper.gnome-shell.overrideAttrs (old: {
          version = "mobile-${source-gnome-shell.version}";
          inherit (source-gnome-shell) src;
          postPatch =
            ''
              # suppress error, will be removed in the original patch
              touch data/theme/gnome-shell.css
            ''
            + old.postPatch;
        });

        mutter = gsuper.mutter.overrideAttrs (old: {
          version = "mobile-${source-gnome-shell.version}";
          inherit (source-mutter) src;
        });
      });
    })
  ];
}
