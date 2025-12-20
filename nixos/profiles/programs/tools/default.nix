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
  programs.htop = {
    enable = true;
    settings = {
      show_program_path = 0;
      highlight_base_name = 1;
    };
  };
  programs.nh.enable = true;
  programs.git.enable = true;
  environment.systemPackages =
    with pkgs;
    [
      # keep-sorted start
      bat
      bc
      binutils
      btop
      compsize
      coreutils
      cryptsetup
      dool
      dosfstools
      efibootmgr
      efitools
      eza
      fd
      file
      gptfdisk
      helix
      jq
      jujutsu
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
      pv
      ripgrep
      rlwrap
      s-tui
      stress
      tokei
      unar
      unrar
      unzip
      usbutils
      util-linux
      viddy
      yq-go
      # keep-sorted end
    ]
    ++ optionalPkg pkgs [ "i7z" ]
    ++ [
      # nix tools
      # keep-sorted start
      cabal2nix
      flat-flake
      nil
      nix-du
      nix-melt
      nix-output-monitor
      nix-prefetch-github
      nix-prefetch-scripts
      nix-tree
      nix-update
      nixd
      nixfmt-rfc-style
      nixpkgs-fmt
      nixpkgs-lint
      nixpkgs-review
      nvd
      # keep-sorted end
    ]
    ++ [
      # custom tools
      delink
      tmpTest
    ];
  programs.fish.interactiveShellInit = ''
    function nom --description 'nom wrapper'
      nix $argv --log-format internal-json &| command nom --json
    end

    function nom-hydra --description 'nom wrapper on hydra builders'
      nom --builders @/etc/nix-build-machines/hydra-builder/machines $argv
    end
  '';
  passthru = {
    inherit delink tmpTest;
  };
}
