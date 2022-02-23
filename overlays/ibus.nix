final: prev: {
  ibus = prev.ibus.override {
    withWayland = true;
  };
}
