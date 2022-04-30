{ ... }:

{
  nix = {
    settings.system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];

    settings.auto-optimise-store = true;
    optimise.automatic = true;

    settings.sandbox = true;

    settings.allowed-users = [ "@users" ];
    settings.trusted-users = [ "root" "@wheel" ];

    settings.keep-outputs = true;
    settings.keep-derivations = true;
    settings.fallback = true;

    settings.substituters = [
      "https://cache.li7g.com"
    ];
    settings.trusted-public-keys = [
      "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM="
    ];
  };
}
