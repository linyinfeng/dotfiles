{
  mobile-nixos,
  fetchFromGitLab,
  ...
}:
mobile-nixos.kernel-builder {
  version = "6.6.3";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "sdm845-6.6.3-r3";
    hash = "sha256-StE6pFwSPklhI0xjp85JSPG0yIFOZ6VU72mQoVrIFSo=";
  };

  patches = [];

  isModular = false;
  isCompressed = "gz";
}
