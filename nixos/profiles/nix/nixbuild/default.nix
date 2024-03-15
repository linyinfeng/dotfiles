{ config, pkgs, ... }:
let
  proxyPort = toString config.networking.fw-proxy.ports.mixed;
  proxyCommand =
    if config.networking.fw-proxy.enable then
      "ProxyCommand ${pkgs.netcat}/bin/nc -X 5 -x localhost:${proxyPort} %h %p"
    else
      "";
in
{
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  environment.etc."nix-build-machines/nixbuild/machines".text = ''
    eu.nixbuild.net x86_64-linux,i686-linux,aarch64-linux - 100 1 benchmark,big-parallel
  '';
  environment.etc."nix-build-machines/nixbuild/machines-aarch64-linux-only".text = ''
    eu.nixbuild.net aarch64-linux - 100 1 benchmark,big-parallel
  '';
  environment.shellAliases = {
    nixbuild = ''nix --builders @/etc/nix-build-machines/nixbuild/machines'';
  };
  services.openssh.knownHosts = {
    nixbuild = {
      extraHostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
  sops.secrets."nixbuild/id-ed25519" = {
    neededForUsers = true; # needed for /etc
    sopsFile = config.sops-file.get "common.yaml";
  };
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentityFile /etc/nix-build-machines/nixbuild/key
      ${proxyCommand}
  '';
  environment.etc."nix-build-machines/nixbuild/key" = {
    mode = "440";
    user = config.users.users.nixbuild.name;
    group = config.users.groups.nixbuild.name;
    source = config.sops.secrets."nixbuild/id-ed25519".path;
  };
  users.users.nixbuild = {
    uid = config.ids.uids.nixbuild;
    isSystemUser = true;
    group = config.users.groups.nixbuild.name;
  };
  users.groups.nixbuild = {
    gid = config.ids.gids.nixbuild;
  };
}
