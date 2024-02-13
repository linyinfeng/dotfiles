{config, ...}: let
  dir = "nix-build-machines/hydra-builder";
  keyFile = "${dir}/key";
in {
  nix = {
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };
  # https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds
  environment.etc."${dir}/machines".text = ''
    hydra-builder@nuc  x86_64-linux,i686-linux,aarch64-linux /etc/${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@fsn0 aarch64-linux                         /etc/${keyFile} 2 100
  '';
  environment.etc."${dir}/machines-workstation".text = ''
    hydra-builder@nuc       x86_64-linux,i686-linux /etc/${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@xps8930   x86_64-linux,i686-linux /etc/${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@framework x86_64-linux,i686-linux /etc/${keyFile} 8 100 kvm,nixos-test,benchmark,big-parallel
    hydra-builder@hil0      x86_64-linux,i686-linux /etc/${keyFile} 2 50

    hydra-builder@fsn0      aarch64-linux /etc/${keyFile} 2 100 benchmark,big-parallel
    hydra-builder@nuc       aarch64-linux /etc/${keyFile} 8 50  kvm,nixos-test
    hydra-builder@xps8930   aarch64-linux /etc/${keyFile} 8 50  kvm,nixos-test
    hydra-builder@framework aarch64-linux /etc/${keyFile} 8 50  kvm,nixos-test
  '';
  sops.secrets."hydra_builder_private_key" = {
    neededForUsers = true; # needed for /etc
    terraformOutput.enable = true;
    restartUnits = []; # nothing
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
