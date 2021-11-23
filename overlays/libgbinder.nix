final: prev: {
  libgbinder = prev.libgbinder.overrideAttrs (old: {
    version = "7f12f1a";
    src = final.fetchFromGitHub {
      owner = "mer-hybris";
      repo = "libgbinder";
      rev = "7f12f1a476cdf60594bad06237e0c762d2ee35db";
      hash = "sha256-2qY7R19IEgZba0E6EBx0zvK9eh5O7G3YRJbQGpRpujM=";
    };
  });
}
