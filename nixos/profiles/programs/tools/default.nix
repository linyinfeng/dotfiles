{ config, pkgs, ... }:
let
  inherit (config.lib.self) optionalPkg;
  delink = pkgs.writeShellApplication {
    name = "delink";
    text = ''
      file="$1"

      if [ ! -h "$file" ]; then
        echo "'$file' is not a symbolic link" >&2
        exit 1
      fi

      target=$(readlink "$file")
      rm -v "$file"
      cp -v "$target" "$file"
      chmod -v u+w "$file"
    '';
  };

  tmpTest = pkgs.writeShellApplication {
    name = "tmp-test";
    text = ''
      mkdir -p /tmp/test
      cd /tmp/test
      exec "$SHELL"
    '';
  };
in
{
  environment.systemPackages =
    with pkgs;
    [
      # sorted list for convenience
      # simply sort by
      # cat | sort | wl-copy
      bat
      bc
      binutils
      btop
      compsize
      coreutils
      cryptsetup
      dosfstools
      dstat
      efibootmgr
      efitools
      eza
      fd
      file
      git
      gptfdisk
      htop
      jq
      keyutils
      libtree
      lm_sensors
      minicom
      moreutils
      ncdu
      openssl
      p7zip
      parted
      patchelf
      pciutils
      powerstat
      powertop
      procs
      ripgrep
      rlwrap
      tmux
      unar
      unrar
      unzip
      usbutils
      util-linux
      yq-go
    ]
    ++ optionalPkg pkgs [ "i7z" ]
    ++ [
      # nix tools
      cabal2nix
      flat-flake
      nil
      nix-du
      nix-eval-jobs
      nix-fast-build
      nixfmt
      nix-melt
      nix-output-monitor
      nixpkgs-fmt
      nixpkgs-lint
      nixpkgs-review
      nix-prefetch-github
      nix-prefetch-scripts
      nix-tree
      nix-update
    ]
    ++ [
      # custom tools
      delink
      tmpTest
    ];
  passthru = {
    inherit delink tmpTest;
  };
}
