final: prev: {
  gnuradio = prev.gnuradio.override {
    unwrapped = prev.gnuradio.unwrapped.override {
      soapysdr = final.soapysdr-with-plugins;
    };
  };
}
