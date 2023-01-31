{ config, ... }:

let
  keyFile = "nix-build-machines/hydra-builder/key";
  machineFile = "nix-build-machines/hydra-builder/machines";
in
{
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  environment.etc.${machineFile}.text = ''
    hydra-builder@nuc.ts.li7g.com x86_64-linux,i686-linux /etc/${keyFile} 1 1 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@a1.ts.li7g.com aarch64-linux /etc/${keyFile} 1 1 benchmark,big-parallel
  '';
  services.openssh.knownHosts = {
    nuc = {
      extraHostNames = [ "nuc.ts.li7g.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzE483giZI140MvDx3S/rWUzZzuyylGHOArhdSRQmyG";
    };
    a1 = {
      extraHostNames = [ "a1.ts.li7g.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBBnpsC3FR75rNNCaxOd1YXjzskIcfXbGJCLzEg46H/";
    };
  };
  sops.secrets."hydra_builder_private_key" = {
    neededForUsers = true; # needed for /etc
    sopsFile = config.sops-file.terraform;
  };
  environment.etc.${keyFile} = {
    mode = "400";
    source = config.sops.secrets."hydra_builder_private_key".path;
  };
  systemd.tmpfiles.rules = [
    "a+ /etc/${keyFile} - - - - group:hydra-builder:r"
  ];
  users.groups.hydra-builder = {
    gid = config.ids.gids.hydra-builder;
  };
}
