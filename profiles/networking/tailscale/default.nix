{ ... }:

{
  services.tailscale.enable = true;
  environment.global-persistence.directories = [
    "/var/lib/tailscale"
  ];
}
