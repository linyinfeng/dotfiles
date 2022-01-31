{ self, config, lib, pkgs, ... }:
let inherit (lib) fileContents;
in
{
  # Sets nrdxp.cachix.org binary cache which just speeds up some builds
  imports = [ ../cachix ];

  # For rage encryption, all hosts need a ssh key pair
  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault false;
  };

  environment = {

    # Selection of sysadmin tools that can come in handy
    systemPackages = with pkgs; [
      coreutils
      curl
      direnv
      dnsutils
      dosfstools
      fd
      git
      gptfdisk
      iputils
      jq
      manix
      moreutils
      nix-index
      ripgrep
      usbutils
      util-linux
      whois
    ];
  };

  networking.useDHCP = false;

  fonts = {
    fonts = with pkgs; [ powerline-fonts dejavu_fonts ];

    fontconfig.defaultFonts = {

      monospace = [ "DejaVu Sans Mono for Powerline" ];

      sansSerif = [ "DejaVu Sans" ];

    };
  };

  nix = {

    # This is just a representation of the nix default
    settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];

    # Improve nix store disk usage
    settings.auto-optimise-store = true;
    gc.automatic = true;
    optimise.automatic = true;

    # Prevents impurities in builds
    settings.sandbox = true;

    settings.allowed-users = [ "@users" ];

    # give root and @wheel special privileges with nix
    settings.trusted-users = [ "root" "@wheel" ];

    # Generally useful nix option defaults
    extraOptions = ''
      # min-free = 536870912
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';

  };

  programs.bash = {
    # Enable direnv, a tool for managing shell environments
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
  };

  # Service that makes Out of Memory Killer more effective
  services.earlyoom.enable = true;

}
