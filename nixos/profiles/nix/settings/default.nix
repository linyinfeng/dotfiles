{ config, lib, ... }:
lib.mkMerge [
  {
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "auto-allocate-uids"
      ];

      settings.auto-allocate-uids = true;

      # auto-optimise-store to decrease TBW to SSD
      settings.auto-optimise-store = true;
      optimise.automatic = lib.mkDefault true;

      settings.sandbox = true;

      settings.allowed-users = [ "@users" ];
      settings.trusted-users = [
        "root"
        "@wheel"
      ];

      settings.keep-outputs = true;
      settings.keep-derivations = true;
      settings.fallback = true;

      settings.use-xdg-base-directories = true;
    };

    nix.channel.enable = false;
    # TODO wait for https://github.com/NixOS/nix/issues/9574
    # `nix.channel.enable = false` will set 'nix-path =' in system nix.conf
    nix.settings.nix-path = config.nix.nixPath;

    systemd.services.nix-daemon.serviceConfig = {
      Slice = "minor.slice";
      CPUWeight = "idle";
    };

    environment.global-persistence.user.directories = [ ".cache/nix" ];
  }
  {
    nix.settings = {
      substituters = [ "https://cache.li7g.com" ];
      trusted-public-keys = [
        "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM="
      ];
    };
  }
  {
    nix.settings = {
      substituters = [ "https://cache.garnix.io" ];
      trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  }
  {
    nix.settings = {
      substituters = [ "https://attic.xuyh0120.win/lantian" ];
      trusted-public-keys = [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
    };
  }
]
