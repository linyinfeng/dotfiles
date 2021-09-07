{ ... }:

{
  virtualisation.anbox = {
    # enable = true; # TODO: broken
    ipv4.dns = "8.8.8.8";
  };
  environment.global-persistence.directories = [
    "/var/lib/anbox"
  ];
}
