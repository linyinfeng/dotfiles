{ config, lib, ... }:
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

    settings.substituters = [
      "https://cache.li7g.com"
      # TODO slow
      # "https://cache.garnix.io"
      # "https://oranc.li7g.com/ghcr.io/linyinfeng/oranc-cache"
    ];
    settings.trusted-public-keys = [
      "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM="
      # TODO slow
      # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];

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
