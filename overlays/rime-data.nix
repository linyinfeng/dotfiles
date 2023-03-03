# TODO wait for https://nixpk.gs/pr-tracker.html?pr=219315
channels: final: prev: {
  inherit (channels.nixpkgs-rime-data)
    fcitx5-with-addons
    ibus-with-plugins;
  ibus-engines = prev.ibus-engines // {
    rime = channels.nixpkgs-rime-data.ibus-engines.rime;
  };
}
