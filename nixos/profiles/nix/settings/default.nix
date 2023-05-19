{...}: {
  nix = {
    settings.experimental-features = ["nix-command" "flakes" "ca-derivations"];
    settings.system-features = ["nixos-test" "benchmark" "big-parallel" "kvm"];

    # use periodic store optimisation
    # settings.auto-optimise-store = true;
    optimise.automatic = true;

    settings.sandbox = true;

    settings.allowed-users = ["@users"];
    settings.trusted-users = ["root" "@wheel"];

    settings.keep-outputs = true;
    settings.keep-derivations = true;
    settings.fallback = true;

    settings.substituters = [
      "https://cache.li7g.com"
      "https://oranc.li7g.com/ghcr.io/linyinfeng/oranc-cache"
    ];
    settings.trusted-public-keys = [
      "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM="
    ];
  };
}
