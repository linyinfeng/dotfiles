{ mobile-nixos, fetchFromGitLab, ... }:
mobile-nixos.kernel-builder {
  version = "6.9.0";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "sdm845-6.9.0";
    hash = "sha256-7QRhleNmvE+1XqwwzOpAb31n9NIwVSVnLoTNZw0Yj40=";
  };

  patches = [ ];

  isModular = false;
  isCompressed = "gz";
}
