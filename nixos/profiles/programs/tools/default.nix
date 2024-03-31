{ pkgs, ... }:
let
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
  environment.systemPackages = with pkgs; [
    bc
    btop
    compsize
    coreutils
    cryptsetup
    dosfstools
    dstat
    efibootmgr
    eza
    fd
    file
    git
    gptfdisk
    htop
    jq
    keyutils
    lm_sensors
    minicom
    moreutils
    ncdu
    openssl
    parted
    pciutils
    procs
    ripgrep
    rlwrap
    tmux
    usbutils
    util-linux
    yq-go

    delink
    tmpTest
  ];
  passthru = {
    inherit delink;
  };
}
