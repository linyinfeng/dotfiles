# TODO wait for https://nixpk.gs/pr-tracker.html?pr=219315
channels: final: prev: {
  ibus-engines = prev.ibus-engines // {
    rime = channels.nixpkgs-ibus-rime-data.ibus-engines.rime;
  };
}
