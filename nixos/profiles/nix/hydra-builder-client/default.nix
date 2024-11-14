{ config, ... }:
let
  dir = "nix-build-machines/hydra-builder";
  keyFile = config.sops.secrets."hydra_builder_private_key".path;
in
{
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  # https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds
  environment.etc."${dir}/machines".text = ''
    hydra-builder@nuc  x86_64-linux,i686-linux,aarch64-linux ${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@fsn0 aarch64-linux                         ${keyFile} 2 200 benchmark,big-parallel
  '';
  environment.etc."${dir}/machines-workstation".text = ''
    hydra-builder@nuc       x86_64-linux,i686-linux ${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@xps8930   x86_64-linux,i686-linux ${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@owl x86_64-linux,i686-linux ${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel

    hydra-builder@fsn0      aarch64-linux ${keyFile} 2 100 benchmark,big-parallel
    hydra-builder@nuc       aarch64-linux ${keyFile} 8 50
    hydra-builder@xps8930   aarch64-linux ${keyFile} 8 50
    hydra-builder@owl aarch64-linux ${keyFile} 8 50
  '';
  sops.secrets."hydra_builder_private_key" = {
    terraformOutput.enable = true;
    mode = "440";
    owner = config.users.users.hydra-builder-client.name;
    group = config.users.groups.hydra-builder-client.name;
    restartUnits = [ ]; # nothing
  };
  users.users.hydra-builder-client = {
    uid = config.ids.uids.hydra-builder-client;
    isSystemUser = true;
    group = config.users.groups.hydra-builder-client.name;
  };
  users.groups.hydra-builder-client = {
    gid = config.ids.gids.hydra-builder-client;
  };
}
