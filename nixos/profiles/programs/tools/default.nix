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

  nomWrapper = pkgs.writeShellApplication {
    name = "nom";
    runtimeInputs = with pkgs; [
      nix-output-monitor
    ];
    text = ''
      nix "$@" --log-format internal-json |& command nom --json
    '';
  };

  nomHydra = pkgs.writeShellApplication {
    name = "nom-hydra";
    runtimeInputs = [ nomWrapper ];
    text = ''
      exec nom --builders "@/etc/nix-build-machines/hydra-builder/machines" "$@"
    '';
  };

  json2nix = pkgs.writeShellApplication {
    name = "json2nix";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      tmp_file=$(mktemp -t json2nix.XXXXXX)
      # function cleanup {
      #   rm -r "$tmp_file"
      # }
      # trap cleanup EXIT
      cat >"$tmp_file"
      nix eval --expr "builtins.fromJSON (builtins.readFile $tmp_file)" --impure | nixfmt - | bat --language=nix
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
      ast-grep
      bat
      bc
      binutils
      btop
      compsize
      coreutils
      cryptsetup
      difftastic
      dool
      dosfstools
      efibootmgr
      efitools
      eza
      fd
      file
      gptfdisk
      grit
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
      sd
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
      nix-prefetch-github
      nix-prefetch-scripts
      nix-tree
      nix-update
      nixd
      nixfmt
      nixpkgs-fmt
      nixpkgs-lint
      nixpkgs-review
      nvd
      # keep-sorted end
    ]
    ++ [
      # custom tools
      # keep-sorted start
      delink
      json2nix
      nomHydra
      nomWrapper
      tmpTest
      # keep-sorted end
    ];
  passthru = {
    inherit delink tmpTest;
  };
}
