channels: final: prev: {

  __dontExport = true; # overrides clutter up actual creations

  gnomeExtensions = prev.gnomeExtensions // {
    dash-to-panel = channels.latest.gnomeExtensions.dash-to-panel;
  };
}
