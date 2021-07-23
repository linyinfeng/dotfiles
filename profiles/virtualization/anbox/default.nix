{ ... }:

{
  virtualisation.anbox = {
    enable = true;
    ipv4.dns = "8.8.8.8";
  };
  environment.global-persistence.directories = [
    "/var/lib/anbox"
  ];
}
