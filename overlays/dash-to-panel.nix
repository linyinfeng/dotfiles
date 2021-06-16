channels: final: prev: {

  __dontExport = true; # overrides clutter up actual creations

  gnomeExtensions = prev.gnomeExtensions // {
    dash-to-panel = prev.gnomeExtensions.dash-to-panel.overrideAttrs
      (old: rec {
        version = final.srcs.dash-to-panel.version;
        src = final.srcs.dash-to-panel.outPath;
      });
  };
}
