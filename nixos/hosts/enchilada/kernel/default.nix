{ mobile-nixos, fetchFromGitLab, ... }:
mobile-nixos.kernel-builder {
  version = "6.7.8";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "sdm845-6.7.8";
    hash = "sha256-vefydDqyGMs1w2I8RIitzEJ/V+MiBCqQMGECwxjixD4=";
  };

  patches = [ ];

  isModular = false;
  isCompressed = "gz";
}
