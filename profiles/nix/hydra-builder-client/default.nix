{ config, ... }:

{
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  environment.etc."nix-build-machines/hydra-builder/machines".text = ''
    hydra-builder@nuc.zt.li7g.com x86_64-linux,i686-linux,aarch64-linux - 1 1 kvm,nixos-test,benchmark,big-parallel
  '';
  services.openssh.knownHosts = {
    nuc = {
      extraHostNames = [ "nuc.zt.li7g.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzE483giZI140MvDx3S/rWUzZzuyylGHOArhdSRQmyG";
    };
  };
  sops.secrets."hydra_builder_private_key" = {
    neededForUsers = true; # needed for /ect
    sopsFile = config.sops.secretsDir + /terraform/hosts/nuc.yaml;
  };
  programs.ssh.extraConfig = ''
    Host nuc.zt.li7g.com
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentityFile /etc/nix-build-machines/hydra-builder/key
  '';
  environment.etc."nix-build-machines/hydra-builder/key" = {
    mode = "copy";
    source = config.sops.secrets."hydra_builder_private_key".path;
  };
  systemd.tmpfiles.rules = [
    "a+ /etc/nix-build-machines/hydra-builder/key - - - - group:hydra-builder:r"
  ];
  users.groups.hydra-builder = {
    gid = config.ids.gids.hydra-builder;
  };
}
