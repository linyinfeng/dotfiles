{ config, pkgs, ... }:

let
  proxyPort = toString config.networking.fw-proxy.mixinConfig.mixed-port;
  proxyCommand =
    if config.networking.fw-proxy.enable
    then "ProxyCommand ${pkgs.netcat}/bin/nc -X 5 -x localhost:${proxyPort} %h %p"
    else "";
in
{
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
    # buildMachines = [
    #   {
    #     hostName = "eu.nixbuild.net";
    #     system = "x86_64-linux";
    #     maxJobs = 100;
    #     supportedFeatures = [ "benchmark" "big-parallel" ];
    #   }
    # ];
  };
  environment.etc."nixbuild/machines".text = ''
    eu.nixbuild.net x86_64-linux - 100 1 benchmark,big-parallel
  '';
  environment.shellAliases = {
    nixbuild = ''nix --builders @/etc/nixbuild/machines'';
  };

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentityFile ${config.age.secrets."nixbuild-id-ed25519".path}
      ${proxyCommand}
  '';
  age.secrets."nixbuild-id-ed25519".file = ../../../secrets/yinfeng-id-ed25519.age;
  services.openssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
}
