{config, ...}: let
  keyFile = "nix-build-machines/hydra-builder/key";
  machineFile = "nix-build-machines/hydra-builder/machines";
in {
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  environment.etc.${machineFile}.text = ''
    hydra-builder@nuc x86_64-linux,i686-linux,aarch64-linux /etc/${keyFile} 8 1 kvm,nixos-test,benchmark,big-parallel
  '';
  sops.secrets."hydra_builder_private_key" = {
    neededForUsers = true; # needed for /etc
    sopsFile = config.sops-file.terraform;
  };
  environment.etc.${keyFile} = {
    mode = "440";
    user = config.users.users.hydra-builder-client.name;
    group = config.users.groups.hydra-builder-client.name;
    source = config.sops.secrets."hydra_builder_private_key".path;
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
