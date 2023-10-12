{pkgs, ...}: let
  delink = pkgs.writeShellApplication {
    name = "delink";
    runtimeInputs = with pkgs; [coreutils];
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
in {
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
    lm_sensors
    moreutils
    ncdu
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
  ];
  passthru = {inherit delink;};
}
